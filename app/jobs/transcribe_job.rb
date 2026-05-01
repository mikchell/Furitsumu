class TranscribeJob < ApplicationJob
  queue_as :default

  retry_on WhisperApiClient::RateLimitError, wait: :polynomially_longer, attempts: 3
  retry_on WhisperApiClient::Error, wait: 5.seconds, attempts: 3

  discard_on ActiveRecord::RecordNotFound

  def perform(entry_id)
    entry = Entry.find(entry_id)
    return unless entry.transcribing?
    return fail_entry!(entry, "音声ファイルが見つかりませんでした。") unless entry.audio_file.attached?

    transcript = download_and_transcribe(entry)

    entry.update!(
      transcript: transcript,
      status: :summarizing
    )
    entry.broadcast_details_update

    SummarizeJob.perform_later(entry.id)
  rescue WhisperApiClient::AuthError, WhisperApiClient::Error => e
    persist_failure(entry, e.message)
    entry&.broadcast_details_update
    raise
  end

  private

  def download_and_transcribe(entry)
    blob = entry.audio_file.blob
    ext  = blob.filename.extension.presence || "webm"

    Tempfile.create(["furitsumu_audio", ".#{ext}"], binmode: true) do |tmpfile|
      entry.audio_file.download { |chunk| tmpfile.write(chunk) }
      tmpfile.rewind

      WhisperApiClient.new.transcribe(tmpfile, filename: blob.filename.to_s)
    end
  end

  def fail_entry!(entry, message)
    persist_failure(entry, message)
    entry.broadcast_details_update
  end

  def persist_failure(entry, message)
    entry.assign_attributes(status: :failed, error_message: message)
    entry.save!(validate: false)
  end
end
