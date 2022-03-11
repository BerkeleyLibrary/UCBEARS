module LendingHelper
  def format_value(value)
    return format_duration(value) if value.is_a?(ActiveSupport::Duration)
    return format_values(value) if value.respond_to?(:map)
    return format_date(value) if value.respond_to?(:strftime)

    value
  end

  def format_date(date, format: :short)
    I18n.l(date, format: format)
  end

  # rubocop:disable Rails/OutputSafety
  def format_values(values)
    values.map { |v| tag.p(format_value(v)) }.join.html_safe
  end
  # rubocop:enable Rails/OutputSafety

  class << self
    include LendingHelper
  end
end
