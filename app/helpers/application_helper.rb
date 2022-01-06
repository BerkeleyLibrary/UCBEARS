require 'dotiw'

module ApplicationHelper
  # ------------------------------------------------------------
  # Message / text helpers

  def app_title
    t(:app_title)
  end

  def app_title_short
    t(:app_title_short)
  end

  def page_header
    content_for(:page_title)
  end

  def page_title
    (title = page_header) ? "#{app_title_short}: #{title}" : app_title
  end

  # ------------------------------------------------------------
  # Link helpers

  def admin_path
    items_path
  end

  def root_link
    link_to(app_title_short, root_path)
  end

  def logout_link
    link_to 'CalNet Logout', logout_path if authenticated?
  end

  def questions_link
    mail_to support_email, 'Questions?'
  end

  # ------------------------------------------------------------
  # HTML helpers

  def format_duration(duration, value_for_nil: nil)
    return value_for_nil unless duration
    raise ArgumentError, "Not a duration: #{duration.inspect}" unless duration.respond_to?(:seconds)
    return format_duration(duration.seconds) unless duration.is_a?(ActiveSupport::Duration)

    distance_of_time_in_words(duration, 0, { only: %i[hours minutes], two_words_connector: ', ' })
  end
end
