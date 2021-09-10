module StatsHelper
  def csv_filename_for(date)
    return 'ucbears-lending.csv' unless date

    "ucbears-lending-#{date.iso8601}.csv"
  end
end
