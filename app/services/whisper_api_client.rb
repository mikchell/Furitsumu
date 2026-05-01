require "json"
require "net/http"
require "uri"

class WhisperApiClient
  API_URL = "https://api.openai.com/v1/audio/transcriptions"
  MODEL   = "whisper-1"
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 120
  CONTENT_TYPES = {
    "m4a" => "audio/mp4",
    "mp3" => "audio/mpeg",
    "mp4" => "audio/mp4",
    "mpeg" => "audio/mpeg",
    "mpga" => "audio/mpeg",
    "wav" => "audio/wav",
    "webm" => "audio/webm"
  }.freeze

  class Error < StandardError; end
  class AuthError < Error; end
  class RateLimitError < Error; end

  def transcribe(tempfile, filename:, language: "ja")
    response = post_multipart(tempfile, filename:, language:)
    parse_response!(response)
  rescue IOError, SocketError, SystemCallError, Timeout::Error, EOFError => e
    raise Error, "Whisper API request failed: #{e.message}"
  end

  private

  def post_multipart(tempfile, filename:, language:)
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

      request.set_form(
        [
          ["file", tempfile, { filename:, content_type: content_type_for(filename) }],
          ["model", MODEL],
          ["language", language],
          ["response_format", "text"]
        ],
        "multipart/form-data"
      )

      http.request(request)
    end
  end

  def parse_response!(response)
    case response.code.to_i
    when 200
      response.body.strip
    when 401
      raise AuthError, "OpenAI API key is invalid or missing"
    when 429
      raise RateLimitError, "OpenAI rate limit exceeded"
    else
      raise Error, "Whisper API error #{response.code}: #{error_body(response)}"
    end
  end

  def api_key
    ENV.fetch("OPENAI_API_KEY") { raise AuthError, "OPENAI_API_KEY is not set" }
  end

  def content_type_for(filename)
    extension = File.extname(filename.to_s).delete(".").downcase
    CONTENT_TYPES.fetch(extension, "application/octet-stream")
  end

  def error_body(response)
    body = JSON.parse(response.body)
    body.dig("error", "message").presence || response.body
  rescue JSON::ParserError
    response.body
  end
end
