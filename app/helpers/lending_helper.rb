module LendingHelper
  def format_html_id(value)
    value.downcase.gsub(/[^A-Za-z0-9_:.-]/, '-')
  end

  def format_value(value)
    return format_values(value) if value.respond_to?(:map)
    return format_date(value) if value.respond_to?(:strftime)

    value
  end

  def format_date(date, format: :short)
    I18n.l(date, format: format)
  end

  def format_values(values)
    values.map { |v| tag.p(format_value(v)) }.join.html_safe
  end

  class << self
    include LendingHelper
  end
end
