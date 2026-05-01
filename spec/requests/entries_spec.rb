require "rails_helper"

RSpec.describe "Entries", type: :request do
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
end
