require 'dotiw'

module ApplicationHelper
  def alerts
    content_tag(:div, class: 'alerts mt-4') do
      flash.each do |lvl, msgs|
        msgs = [msgs] if msgs.is_a?(String)
        msgs.each do |msg|
          concat content_tag(:div, msg.html_safe, class: "alert alert-#{lvl}")
        end
      end
    end
  end

  def questions_link
    mail_to support_email, 'Questions?', class: 'support-email'
  end

  def logout_link
    link_to 'CalNet Logout', logout_path, class: 'nav-link' if authenticated?
  end

  def logo_link
    link_to(
      image_tag('logo.png', height: '30', alt: 'UC Berkeley Library'),
      'http://www.lib.berkeley.edu/',
      { class: 'navbar-brand no-link-style' }
    )
  end

  def page_title
    return content_for :page_title if content_for?(:page_title)
  end

  def format_duration(duration, value_for_nil: nil)
    return value_for_nil unless duration
    raise ArgumentError, "Not a duration: #{duration.inspect}" unless duration.respond_to?(:seconds)
    return format_duration(duration.seconds) unless duration.is_a?(ActiveSupport::Duration)

    distance_of_time_in_words(duration, 0, { only: %i[hours minutes], two_words_connector: ', ' })
  end
end
