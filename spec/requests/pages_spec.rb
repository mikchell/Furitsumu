require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "renders the landing page for guests" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("思考の地層")
    end
  end
end
