module ApplicationHelper
  # Turn a Graph API created_time (e.g. "2026-07-27T14:02:29+0000") into a
  # human-readable string in Bangkok time, e.g. "Jul 27, 2026 · 9:02 PM".
  def format_chat_time(iso)
    return "" if iso.blank?
    Time.parse(iso.to_s).in_time_zone("Asia/Bangkok").strftime("%b %-d, %Y · %-I:%M %p")
  rescue ArgumentError
    iso.to_s
  end
end
