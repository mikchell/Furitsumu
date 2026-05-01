class LlmApiClient
  API_URL = "https://api.anthropic.com/v1/messages"
  MODEL   = "claude-haiku-4-5-20251001"

  SUMMARY_PROMPT = <<~PROMPT
    あなたはユーザーが毎日3分話す日記の要約者です。
    以下の文字起こしテキストを、1行(40文字以内)で要約してください。

    条件:
    - 一人称(私は〜)で書く
    - その日の出来事や気持ちのエッセンスを抽出
    - 客観的な記述ではなく、ユーザーの内面が見える表現
    - 「〜した日」「〜と感じた日」のような着地が好ましい

    例: 「同期との会話で自分の弱さを認められた日」
       「進捗が出なくて焦りを感じた日」

    文字起こしテキスト:
    %{transcript}
  PROMPT

  class Error < StandardError; end
  class AuthError < Error; end
  class RateLimitError < Error; end

  def summarize(transcript)
    prompt = SUMMARY_PROMPT % { transcript: transcript.strip }
    response = post_message(prompt)
    parse_response!(response)
  end

  private

  def post_message(prompt)
    uri = URI(API_URL)

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Post.new(uri)
      request["x-api-key"]         = api_key
      request["anthropic-version"]  = "2023-06-01"
      request["content-type"]       = "application/json"

      request.body = {
        model: MODEL,
        max_tokens: 100,
        messages: [{ role: "user", content: prompt }]
      }.to_json

      http.request(request)
    end
  end

  def parse_response!(response)
    case response.code.to_i
    when 200
      body = JSON.parse(response.body)
      body.dig("content", 0, "text").to_s.strip
    when 401
      raise AuthError, "Anthropic API key is invalid or missing"
    when 429
      raise RateLimitError, "Anthropic rate limit exceeded"
    else
      raise Error, "LLM API error #{response.code}: #{response.body}"
    end
  end

  def api_key
    ENV.fetch("ANTHROPIC_API_KEY") { raise AuthError, "ANTHROPIC_API_KEY is not set" }
  end
end
