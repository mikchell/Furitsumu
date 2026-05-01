require "json"
require "net/http"
require "uri"

class LlmApiClient
  API_URL = "https://api.openai.com/v1/chat/completions"
  MODEL   = "gpt-4.1-mini"
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 120

  SUMMARY_SYSTEM_PROMPT = <<~PROMPT
    あなたはユーザーが毎日3分話す日記の要約者です。
    文字起こしテキストを、日本語で自然に要約してください。

    条件:
    - その日の出来事、気持ち、考えていたことが自然に伝わるようにまとめる
    - 不自然に短くせず、必要なら2〜4文程度で要約する
    - 箇条書きではなく、読みやすい自然な文章にする
    - 余計な前置きや説明は入れず、要約本文だけを返す
  PROMPT

  class Error < StandardError; end
  class AuthError < Error; end
  class RateLimitError < Error; end

  def summarize(transcript)
    response = post_message(transcript.to_s.strip)
    parse_response!(response)
  rescue IOError, SocketError, SystemCallError, Timeout::Error, EOFError => e
    raise Error, "OpenAI summary request failed: #{e.message}"
  end

  private

  def post_message(transcript)
    uri = URI(API_URL)

    Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: true,
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    ) do |http|
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"

      request.body = {
        model: MODEL,
        max_tokens: 100,
        messages: [
          { role: "system", content: SUMMARY_SYSTEM_PROMPT },
          { role: "user", content: transcript }
        ]
      }.to_json

      http.request(request)
    end
  end

  def parse_response!(response)
    case response.code.to_i
    when 200
      body = JSON.parse(response.body)
      body.dig("choices", 0, "message", "content").to_s.strip
    when 401
      raise AuthError, "OpenAI API key is invalid or missing"
    when 429
      raise RateLimitError, "OpenAI rate limit exceeded"
    else
      raise Error, "LLM API error #{response.code}: #{error_body(response)}"
    end
  end

  def api_key
    ENV.fetch("OPENAI_API_KEY") { raise AuthError, "OPENAI_API_KEY is not set" }
  end

  def error_body(response)
    body = JSON.parse(response.body)
    body.dig("error", "message").presence || response.body
  rescue JSON::ParserError
    response.body
  end
end
