class UserInsightsSnapshot
  Theme = Struct.new(:title, :count, :description, keyword_init: true)
  Signal = Struct.new(:title, :score, :description, keyword_init: true)
  SummaryEntry = Struct.new(:recorded_on, :summary, keyword_init: true)

  THEME_DEFINITIONS = {
    "前に進もうとする軸" => {
      keywords: %w[成長 学び 挑戦 改善 目標 前進 続ける 試す 整理 振り返り],
      description: "停滞よりも前進を選び、次にどう動くかを考える傾向があります。"
    },
    "仕事と集中の軸" => {
      keywords: %w[仕事 進捗 タスク 開発 実装 会議 集中 締切 企画 調整],
      description: "日々の中で、成果や進み具合への意識が強く表れています。"
    },
    "人との関係の軸" => {
      keywords: %w[会話 同期 友達 家族 相手 チーム 相談 共有 信頼 先輩],
      description: "出来事を自分だけで完結させず、人との関係の中で受け止めています。"
    },
    "感情の揺れを捉える軸" => {
      keywords: %w[不安 焦り うれしい 嬉しい 楽しい 苦しい つらい 安心 悔しい 緊張],
      description: "出来事そのものより、そこで自分がどう感じたかを丁寧に見ています。"
    },
    "自分理解の軸" => {
      keywords: %w[自分 本音 気づく 気づき 感じる 弱さ 強み 向き合う 納得 違和感],
      description: "外側の出来事より、自分の内側で何が起きたかに注意が向いています。"
    },
    "暮らしと回復の軸" => {
      keywords: %w[休む 睡眠 体調 散歩 食事 疲れ 回復 余白 リズム 整える],
      description: "成果だけでなく、心身の状態や暮らしの整い方を大事にしています。"
    }
  }.freeze

  SIGNAL_DEFINITIONS = {
    "内省が深い" => {
      keywords: %w[自分 本音 気づく 気づき 感じる 向き合う 違和感 整理],
      description: "出来事の表面より、そこから何を受け取ったかを掘り下げるタイプです。"
    },
    "前進志向が強い" => {
      keywords: %w[成長 学び 挑戦 改善 目標 前進 試す 次 続ける],
      description: "反省だけで終わらせず、次の一手に変換する思考が目立ちます。"
    },
    "対話を通じて考える" => {
      keywords: %w[会話 相談 共有 相手 チーム 同期 家族 信頼 伝える],
      description: "他者とのやり取りを、自分の思考を整えるきっかけとして使っています。"
    },
    "感情の解像度が高い" => {
      keywords: %w[不安 焦り 安心 うれしい 嬉しい 悔しい 緊張 苦しい つらい],
      description: "気持ちの細かな変化に気づきやすく、感情を言葉にする力があります。"
    }
  }.freeze

  KEYWORD_CANDIDATES = (
    THEME_DEFINITIONS.values.flat_map { |definition| definition[:keywords] } +
    SIGNAL_DEFINITIONS.values.flat_map { |definition| definition[:keywords] }
  ).uniq.freeze

  attr_reader :user

  def initialize(user)
    @user = user
    @entries = load_entries
    @combined_text = @entries.map(&:summary).compact.join(" ")
  end

  def present?
    @entries.any?
  end

  def total_entries
    @entries.size
  end

  def active_days
    @entries.map(&:recorded_on).uniq.size
  end

  def latest_recorded_on
    @entries.first&.recorded_on
  end

  def top_themes
    @top_themes ||= ranked_items(THEME_DEFINITIONS, limit: 3, fallback_description: "まだ十分なデータがないため、これから傾向が育っていきます。")
  end

  def style_signals
    @style_signals ||= ranked_items(SIGNAL_DEFINITIONS, limit: 2, fallback_description: "振り返りが増えるほど、その人らしい思考の型が見えてきます。")
  end

  def top_keywords
    @top_keywords ||= KEYWORD_CANDIDATES.filter_map do |keyword|
      count = count_occurrences(@combined_text, keyword)
      next if count.zero?

      [keyword, count]
    end.sort_by { |keyword, count| [-count, keyword] }.first(8).map(&:first)
  end

  def recent_summaries
    @entries.first(6).map do |entry|
      SummaryEntry.new(
        recorded_on: entry.recorded_on,
        summary: entry.summary
      )
    end
  end

  private

  def load_entries
    user.entries.completed.where.not(summary: [nil, ""]).recent_first.to_a
  end

  def ranked_items(definitions, limit:, fallback_description:)
    ranked = definitions.map do |title, definition|
      score = definition[:keywords].sum { |keyword| count_occurrences(@combined_text, keyword) }
      next if score.zero?

      Struct.new(:title, :score, :description, keyword_init: true).new(
        title: title,
        score: score,
        description: definition[:description]
      )
    end.compact.sort_by { |item| [-item.score, item.title] }.first(limit)

    return ranked if ranked.any?

    [
      Struct.new(:title, :score, :description, keyword_init: true).new(
        title: "まだ輪郭を集めている段階",
        score: 0,
        description: fallback_description
      )
    ]
  end

  def count_occurrences(text, keyword)
    text.to_s.scan(keyword).size
  end
end
