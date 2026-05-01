module EntriesHelper
  def entry_status_label(entry)
    case entry.status.to_sym
    when :recording
      "録音中"
    when :transcribing
      "文字起こし中"
    when :summarizing
      "要約中"
    when :completed
      "完了"
    when :failed
      "失敗"
    else
      entry.status.to_s.humanize
    end
  end

  def entry_status_badge_classes(entry)
    base = "status-pill"

    tone = case entry.status.to_sym
           when :completed
             "status-pill-success"
           when :failed
             "status-pill-danger"
           when :transcribing, :summarizing, :recording
             "status-pill-muted"
           else
             "status-pill-muted"
           end

    "#{base} #{tone}"
  end

  def entry_duration_label(entry)
    return unless entry.duration_seconds.present?

    total_seconds = entry.duration_seconds.to_i
    minutes = total_seconds / 60
    seconds = total_seconds % 60

    format("%d:%02d", minutes, seconds)
  end
end
