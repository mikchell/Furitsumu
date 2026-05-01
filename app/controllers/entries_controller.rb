class EntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_entry, only: :show

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

  def create
    @entry = current_user.entries.build(entry_params)
    @entry.recorded_on = today_for(current_user)
    @entry.status = :transcribing

    if @entry.save
      redirect_to @entry, notice: "音声を保存しました。文字起こしの接続は次のステップで追加します。"
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
