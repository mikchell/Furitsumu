require "rails_helper"

RSpec.describe "Entries", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  describe "GET /entries" do
    it "requires authentication" do
      get entries_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "renders successfully for signed-in users" do
      sign_in user

      get entries_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /entries" do
    it "creates one entry for today" do
      sign_in user

      audio = fixture_file_upload(Rails.root.join("spec/fixtures/files/sample_audio.webm"), "audio/webm")

      expect {
        post entries_path, params: {
          entry: {
            audio_file: audio,
            duration_seconds: 90
          }
        }
      }.to change(Entry, :count).by(1)

      expect(Entry.last.recorded_on).to eq(Date.current)
      expect(Entry.last).to be_transcribing
    end
  end

  describe "POST /entries/:id/retry" do
    it "re-enqueues transcription for a stale transcribing entry" do
      sign_in user
      entry = create(:entry, :with_audio, user:, status: :transcribing, transcript: nil, summary: nil)
      entry.update_column(:updated_at, 5.minutes.ago)

      expect {
        post retry_entry_path(entry)
      }.to have_enqueued_job(TranscribeJob).with(entry.id)

      expect(response).to redirect_to(entry_path(entry))
    end

    it "re-enqueues summarization for a stale summarizing entry" do
      sign_in user
      entry = create(:entry, :with_audio, user:, status: :summarizing, transcript: "今日は進め方を整理できた", summary: nil)
      entry.update_column(:updated_at, 5.minutes.ago)

      expect {
        post retry_entry_path(entry)
      }.to have_enqueued_job(SummarizeJob).with(entry.id)

      expect(response).to redirect_to(entry_path(entry))
    end
  end
end
