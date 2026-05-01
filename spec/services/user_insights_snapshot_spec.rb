require "rails_helper"

RSpec.describe UserInsightsSnapshot do
  describe "#top_themes" do
    it "extracts recurring themes and style signals from completed entries" do
      user = create(:user, email: "insights-#{SecureRandom.hex(4)}@example.com")

      create(
        :entry,
        :with_audio,
        user: user,
        status: :completed,
        summary: "私は進捗が出なくて焦りを感じた日"
      )
      create(
        :entry,
        :with_audio,
        user: user,
        status: :completed,
        summary: "私は同期との会話で自分の弱さを認められた日"
      )

      insights = described_class.new(user)

      expect(insights).to be_present
      expect(insights.top_themes.map(&:title)).to include("人との関係の軸", "仕事と集中の軸")
      expect(insights.style_signals.map(&:title)).not_to be_empty
      expect(insights.top_keywords).to include("進捗", "同期")
      expect(insights.recent_summaries.size).to eq(2)
    end

    it "returns a graceful fallback when no summaries exist yet" do
      user = create(:user, email: "empty-insights-#{SecureRandom.hex(4)}@example.com")

      insights = described_class.new(user)

      expect(insights).not_to be_present
      expect(insights.top_themes.first.title).to eq("まだ輪郭を集めている段階")
    end
  end
end
