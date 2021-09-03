class StatsController < ApplicationController
  before_action :require_lending_admin!

  def lending
    respond_to do |format|
      format.csv { send_csv }
    end
  end

  private

  def csv_filename
    return 'ucbears-lending.csv' unless date_param

    "ucbears-lending-#{date_param.iso8601}.csv"
  end

  def all_item_stats
    return ItemLendingStats.all unless date_param

    ItemLendingStats.each_for_date(date_param)
  end

  def send_csv
    send_file_headers!(
      type: 'text/csv; charset=utf-8',
      filename: csv_filename
    )
    self.response_body = Enumerator.new do |y|
      y << CSV.generate_line(ItemLendingStats::CSV_HEADERS)
      all_item_stats.each { |item_stats| item_stats.to_csv(y) }
    end
  end

  def date_param
    @date_param ||= (date_str = params[:date]) && parse_date_param(date_str)
  end

  def parse_date_param(date_str)
    Date.iso8601(date_str)
  rescue Date::Error
    raise ActionController::BadRequest, "#{date_str.inspect} is not a valid ISO8601 date"
  end
end
