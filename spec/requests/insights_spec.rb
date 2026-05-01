require "rails_helper"

RSpec.describe "Insights", type: :request do
  let(:user) { create(:user, email: "insight-request-#{SecureRandom.hex(4)}@example.com") }

  it "requires authentication" do
    get insight_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders the insights page for signed-in users" do
    sign_in user
    create(
      :entry,
      :with_audio,
      user: user,
      status: :completed,
      summary: "私は前に進むために気持ちを整理した日"
    )

    get insight_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("あなたの思考の輪郭")
    expect(response.body).to include("繰り返し現れる関心ごと")
  end
end
