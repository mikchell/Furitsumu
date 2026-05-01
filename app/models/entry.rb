class Entry < ApplicationRecord
  include Turbo::Broadcastable

  STALE_PROCESSING_AFTER = 2.minutes
  belongs_to :user
  has_one_attached :audio_file

  AUDIO_CONTENT_TYPES = %w[
    audio/mp4
    audio/mpeg
    audio/wav
    audio/webm
    video/mp4
  ].freeze

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
  validate :audio_file_presence
  validate :audio_file_content_type

  def broadcast_details_update
    broadcast_replace_to(
      self,
      target: "entry_#{id}_details",
      partial: "entries/details",
      locals: { entry: self }
    )
  end

  def stale_processing?
    return false unless transcribing? || summarizing?
    return false unless updated_at.present?

    updated_at < STALE_PROCESSING_AFTER.ago
  end

  def retryable_processing?
    failed? || stale_processing?
  end

  private

  def audio_file_presence
    errors.add(:audio_file, "を添付してください") unless audio_file.attached?
  end

  def audio_file_content_type
    return unless audio_file.attached?
    return if AUDIO_CONTENT_TYPES.include?(audio_file.blob.content_type)

    errors.add(:audio_file, "は音声ファイルを選択してください")
  end
end
