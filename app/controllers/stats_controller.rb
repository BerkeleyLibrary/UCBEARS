class StatsController < ApplicationController
  before_action :require_lending_admin!

  PROFILE_STATS_HTML = 'stats-profile.html'.freeze

  def download
    respond_to do |format|
      format.csv { send_csv }
    end
  end

  # Stats
  def index; end

  # Stats page, but generate a profile result
  def profile_index
    RubyProf.start
    flash.now[:info] = "<a href=\"/#{PROFILE_STATS_HTML}\">Profile generated.</a>"
    render(:index)
  ensure
    result = RubyProf.stop
    File.open(File.join(File.expand_path('../../public', __dir__), PROFILE_STATS_HTML), 'w') do |f|
      RubyProf::GraphHtmlPrinter.new(result).print(f, min_percent: 2)
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
