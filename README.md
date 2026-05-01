# Furitsumu

> 毎日3分、今日の自分を振り返って、思考を積んでいく音声ジャーナル

Furitsumu は、書く代わりに「話す」ことで振り返りを続けやすくする Rails アプリです。  
現時点では MVP の土台として、認証、日次エントリー、録音 UI、音声添付、一覧・詳細画面までを実装しています。

## コンセプト

- 3 分で終わること
- 話した内容を整理して残すこと
- 続けるほど価値が増すこと

## 現在の実装範囲

- Devise によるユーザー登録 / ログイン
- 1 日 1 エントリーのデータモデル
- MediaRecorder API を使ったブラウザ録音 UI
- Active Storage への音声添付
- エントリー一覧 / 詳細 / 新規作成画面
- RSpec と FactoryBot による基礎テスト

## 次に実装すること

- Sidekiq + Redis の本格接続
- Whisper API での文字起こし
- 1 行サマリー生成
- Turbo Streams による処理状態更新
- Cloudflare R2 または S3 への保存

## セットアップ

```bash
bundle install
bin/rails db:prepare
bin/dev
```

`bin/dev` でアプリを立ち上げる前に、必要なら `foreman` を入れてください。

```bash
gem install foreman
```

## テスト

```bash
bundle exec rspec
```

## 環境変数

今後の API 連携で以下を使う想定です。

- `OPENAI_API_KEY`
- `REDIS_URL`
- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`
- `R2_BUCKET`

## 技術スタック

- Ruby 3.3
- Rails 7.1
- PostgreSQL
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- Devise
- Active Storage
- RSpec / FactoryBot / VCR / WebMock

## 設計メモ

- `entries` は `recorded_on` をキーに 1 日 1 件へ制約
- 音声日記の中心フローは `new -> create -> index/show`
- ステータス enum は将来の非同期処理を見据えて定義済み

## ポートフォリオ観点での見せ場

- 書く日記ではなく音声入力へ振り切ったプロダクト判断
- 3 分制約を UX とデータモデルの両面で守る設計
- AI 要約を前提にした「蓄積される振り返り」体験
