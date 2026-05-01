require "rails_helper"

RSpec.describe LlmApiClient do
  subject(:client) { described_class.new }

  describe "#summarize" do
    it "returns the summary text on success" do
      stub_request(:post, LlmApiClient::API_URL)
        .to_return(status: 200, body: {
          choices: [
            {
              message: {
                content: "私は少し肩の力を抜いて話せた日"
              }
            }
          ]
        }.to_json)

      result = with_api_key { client.summarize("今日は落ち着いて話せた") }

      expect(result).to eq("私は少し肩の力を抜いて話せた日")
    end

    it "raises a rate limit error for 429 responses" do
      stub_request(:post, LlmApiClient::API_URL)
        .to_return(status: 429, body: { error: { message: "Too many requests" } }.to_json)

      expect {
        with_api_key { client.summarize("今日は落ち着いて話せた") }
      }.to raise_error(LlmApiClient::RateLimitError, "OpenAI rate limit exceeded")
    end

    it "surfaces API error messages from the response body" do
      stub_request(:post, LlmApiClient::API_URL)
        .to_return(status: 500, body: { error: { message: "server exploded" } }.to_json)

      expect {
        with_api_key { client.summarize("今日は落ち着いて話せた") }
      }.to raise_error(LlmApiClient::Error, /server exploded/)
    end

    it "wraps network failures in a generic error" do
      stub_request(:post, LlmApiClient::API_URL).to_raise(Timeout::Error.new("execution expired"))

      expect {
        with_api_key { client.summarize("今日は落ち着いて話せた") }
      }.to raise_error(LlmApiClient::Error, /execution expired/)
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
