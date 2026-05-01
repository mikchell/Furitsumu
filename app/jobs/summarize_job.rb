require_relative "../services/llm_api_client"

class SummarizeJob < ApplicationJob
  queue_as :default

  retry_on ::LlmApiClient::RateLimitError, wait: :polynomially_longer, attempts: 3
  retry_on ::LlmApiClient::Error, wait: 5.seconds, attempts: 3

  discard_on ActiveRecord::RecordNotFound

  def perform(entry_id)
    entry = Entry.find(entry_id)
    return unless entry.summarizing?

    summary = ::LlmApiClient.new.summarize(entry.transcript)

    entry.update!(summary:, status: :completed)
    broadcast_update(entry)
  rescue ::LlmApiClient::AuthError, ::LlmApiClient::Error => e
    entry&.update!(status: :failed, error_message: e.message)
    broadcast_update(entry) if entry
    raise
  end

  private

  def broadcast_update(entry)
    entry.broadcast_details_update
  end
end
