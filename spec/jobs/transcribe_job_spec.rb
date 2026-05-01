require "rails_helper"

RSpec.describe TranscribeJob, type: :job do
  include ActiveJob::TestHelper

  let(:entry) { create(:entry, status: :transcribing, transcript: nil, summary: nil) }

  before do
    entry.audio_file.attach(
      io: StringIO.new("fake audio"),
      filename: "sample.webm",
      content_type: "audio/webm"
    )
  end

  it "stores the transcript and enqueues the summarize job" do
    allow_any_instance_of(WhisperApiClient).to receive(:transcribe).and_return("今日は進め方を整理できた")

    expect {
      perform_enqueued_jobs(only: described_class) do
        described_class.perform_later(entry.id)
      end
    }.to have_enqueued_job(SummarizeJob).with(entry.id)

    expect(entry.reload.transcript).to eq("今日は進め方を整理できた")
    expect(entry).to be_summarizing
  end

  it "marks the entry as failed when no audio file is attached" do
    entry.audio_file.purge

    perform_enqueued_jobs(only: described_class) do
      described_class.perform_later(entry.id)
    end

    expect(entry.reload).to be_failed
    expect(entry.error_message).to eq("音声ファイルが見つかりませんでした。")
  end

  it "marks the entry as failed when the API client raises an auth error" do
    allow_any_instance_of(WhisperApiClient).to receive(:transcribe)
      .and_raise(WhisperApiClient::AuthError, "OPENAI_API_KEY is not set")

    described_class.perform_now(entry.id)

    expect(entry.reload).to be_failed
    expect(entry.error_message).to eq("OPENAI_API_KEY is not set")
  end
end
