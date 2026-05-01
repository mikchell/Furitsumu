require "rails_helper"

RSpec.describe Entry, type: :model do
  it "is valid with the factory defaults" do
    expect(build(:entry, :with_audio)).to be_valid
  end

  it "requires an audio file" do
    entry = build(:entry)

    expect(entry).not_to be_valid
    expect(entry.errors[:audio_file]).to include("を添付してください")
  end

  it "accepts a supported audio content type" do
    entry = build(:entry)
    entry.audio_file.attach(
      io: StringIO.new("fake audio"),
      filename: "sample.webm",
      content_type: "audio/webm"
    )

    expect(entry).to be_valid
  end

  it "rejects unsupported file types" do
    entry = build(:entry)
    entry.audio_file.attach(
      io: StringIO.new("not audio"),
      filename: "notes.txt",
      content_type: "text/plain"
    )

    expect(entry).not_to be_valid
    expect(entry.errors[:audio_file]).to include("は音声ファイルを選択してください")
  end

  it "prevents multiple entries on the same day for the same user" do
    user = create(:user)
    create(:entry, :with_audio, user:, recorded_on: Date.current)

    duplicate = build(:entry, :with_audio, user:, recorded_on: Date.current)

    expect(duplicate).not_to be_valid
  end

  it "detects stale transcribing entries" do
    user = create(:user, email: "stale-#{SecureRandom.hex(4)}@example.com")
    entry = create(:entry, :with_audio, user:, status: :transcribing, transcript: nil, summary: nil)
    entry.update_column(:updated_at, 5.minutes.ago)

    expect(entry).to be_stale_processing
    expect(entry).to be_retryable_processing
  end

  it "does not mark fresh processing entries as stale" do
    user = create(:user, email: "fresh-#{SecureRandom.hex(4)}@example.com")
    entry = create(:entry, :with_audio, user:, status: :transcribing, transcript: nil, summary: nil)
    entry.update_column(:updated_at, 30.seconds.ago)

    expect(entry).not_to be_stale_processing
  end
end
