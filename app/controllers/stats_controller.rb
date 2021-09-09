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

  # For debugging
  def all_loan_dates
    all_loan_dates_by_id = ItemLendingStats.all_loan_dates_by_id
    respond_to do |format|
      format.csv do
        rails_loan_dates = LendingItemLoan.pluck(:id, :loan_date).to_h
        send_all_loan_dates_csv(all_loan_dates_by_id, rails_loan_dates)
      end
    end
  end

  private

  def send_all_loan_dates_csv(all_loan_dates_by_id, rails_loan_dates)
    csv_headers = all_loan_dates_by_id.columns + ['rails_loan_date']
    send_file_headers!(type: 'text/csv; charset=utf-8', filename: 'all_loan_dates.csv')
    self.response_body = Enumerator.new do |y|
      y << CSV.generate_line(csv_headers, encoding: 'UTF-8')
      all_loan_dates_by_id.each do |result|
        row = result.values + [rails_loan_dates[result['id']]]
        y << CSV.generate_line(row, encoding: 'UTF-8')
      end
    end
  end

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
      y << CSV.generate_line(ItemLendingStats::CSV_HEADERS, encoding: 'UTF-8')
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
