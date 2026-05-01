class EntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_entry, only: %i[show retry]

  def index
    @entries = current_user.entries.recent_first
    @today_entry = current_user.entries.find_by(recorded_on: today_for(current_user))
  end

  def show
  end

  def new
    existing_entry = current_user.entries.find_by(recorded_on: today_for(current_user))
    return redirect_to existing_entry, alert: "今日はすでに振り返りを保存しています。" if existing_entry

    @entry = current_user.entries.build
  end

  def retry
    unless @entry.retryable_processing?
      return redirect_to @entry, alert: "処理中または完了済みのエントリーは再開できません。"
    end

    if @entry.summarizing? && @entry.transcript.present?
      @entry.update!(error_message: nil)
      SummarizeJob.perform_later(@entry.id)
      redirect_to @entry, notice: "要約処理を再開しました。"
    else
      @entry.update!(status: :transcribing, error_message: nil)
      TranscribeJob.perform_later(@entry.id)
      redirect_to @entry, notice: "文字起こし処理を再開しました。"
    end
  end

  def create
    @entry = current_user.entries.build(entry_params)
    @entry.recorded_on = today_for(current_user)
    @entry.status = :transcribing

    if @entry.save
      TranscribeJob.perform_later(@entry.id)
      redirect_to @entry, notice: "音声を保存しました。文字起こしと要約を処理しています。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_entry
    @entry = current_user.entries.find(params[:id])
  end

  def entry_params
    params.require(:entry).permit(:audio_file, :duration_seconds)
  end

  def today_for(user)
    Time.use_zone(user.timezone.presence || "Asia/Tokyo") { Time.zone.today }
  end
end
