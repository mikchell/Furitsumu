require "rails_helper"

RSpec.describe WhisperApiClient do
  subject(:client) { described_class.new }

  let(:tempfile) do
    Tempfile.create(["audio", ".webm"]).tap do |file|
      file.write("fake audio")
      file.rewind
    end
  end

  after do
    path = tempfile.path
    tempfile.close
    File.delete(path) if File.exist?(path)
  end

  describe "#transcribe" do
    it "returns the transcript body on success" do
      stub_request(:post, WhisperApiClient::API_URL)
        .to_return(status: 200, body: "今日は落ち着いて話せた")

      result = with_api_key { client.transcribe(tempfile, filename: "sample.webm") }

      expect(result).to eq("今日は落ち着いて話せた")
    end

    it "raises a rate limit error for 429 responses" do
      stub_request(:post, WhisperApiClient::API_URL)
        .to_return(status: 429, body: { error: { message: "Too many requests" } }.to_json)

      expect {
        with_api_key { client.transcribe(tempfile, filename: "sample.webm") }
      }.to raise_error(WhisperApiClient::RateLimitError, "OpenAI rate limit exceeded")
    end

    it "surfaces API error messages from the response body" do
      stub_request(:post, WhisperApiClient::API_URL)
        .to_return(status: 500, body: { error: { message: "server exploded" } }.to_json)

      expect {
        with_api_key { client.transcribe(tempfile, filename: "sample.webm") }
      }.to raise_error(WhisperApiClient::Error, /server exploded/)
    end

    it "wraps network failures in a generic error" do
      stub_request(:post, WhisperApiClient::API_URL).to_raise(Timeout::Error.new("execution expired"))

      expect {
        with_api_key { client.transcribe(tempfile, filename: "sample.webm") }
      }.to raise_error(WhisperApiClient::Error, /execution expired/)
    end
  end

  def with_api_key
    original = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "test-openai-key"
    yield
  ensure
    ENV["OPENAI_API_KEY"] = original
  end
end
