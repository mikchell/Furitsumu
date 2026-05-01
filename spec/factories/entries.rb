FactoryBot.define do
  factory :entry do
    association :user
    recorded_on { Date.current }
    duration_seconds { 120 }
    transcript { "今日は集中して作業できた。" }
    summary { "集中して作業の流れを作れた日" }
    status { :completed }
    error_message { nil }

    trait :with_audio do
      after(:build) do |entry|
        entry.audio_file.attach(
          io: StringIO.new("fake audio"),
          filename: "sample.webm",
          content_type: "audio/webm"
        )
      end
    end
  end
end
