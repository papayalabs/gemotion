module ApplicationHelper
  def format_time(seconds)
    return "0:00" if seconds.nil?

    minutes, remaining_seconds = seconds.divmod(60)
    "#{minutes}:#{remaining_seconds.to_i.to_s.rjust(2, '0')}"
  end
end
