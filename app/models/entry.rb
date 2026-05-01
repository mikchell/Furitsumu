class Entry < ApplicationRecord
  belongs_to :user
  has_one_attached :audio_file

  enum :status, {
    recording: 0,
    transcribing: 10,
    summarizing: 20,
    completed: 30,
    failed: 90
  }

  scope :recent_first, -> { order(recorded_on: :desc, created_at: :desc) }

  validates :recorded_on, presence: true, uniqueness: { scope: :user_id }
  validates :duration_seconds, numericality: { greater_than: 0, less_than_or_equal_to: 180 }, allow_nil: true
  validates :status, presence: true
end
