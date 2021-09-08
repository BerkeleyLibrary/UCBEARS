# rubocop:disable Metrics/ClassLength
class ItemLendingStats
  include Comparable

  # ------------------------------------------------------------
  # Constants

  SELECT_DISTINCT_LOAN_DATES_STMT = 'SELECT_DISTINCT_LOAN_DATES'.freeze
  SELECT_DISTINCT_LOAN_DATES = <<~SQL.freeze
      SELECT DISTINCT DATE((loan_date AT TIME ZONE 'UTC') AT TIME ZONE ?)
        FROM lending_item_loans
    ORDER BY 1 DESC
  SQL

  SELECT_LOAN_DATES_BY_ID_STMT = 'SELECT_LOAN_DATES_BY_ID'.freeze
  SELECT_LOAN_DATES_BY_ID = <<~SQL.freeze
      SELECT id, DATE((loan_date AT TIME ZONE 'UTC') AT TIME ZONE ?)
        FROM lending_item_loans
    ORDER BY 1 DESC
  SQL

  SELECT_ALL_LOAN_DURATIONS = <<~SQL.freeze
    SELECT return_date - loan_date AS loan_duration
      FROM lending_item_loans AS returned_loans
     WHERE return_date IS NOT NULL

    UNION ALL

    SELECT due_date - loan_date AS loan_duration
      FROM lending_item_loans AS expired_loans
     WHERE return_date IS NULL
       AND (due_date AT TIME ZONE 'UTC')
           <= (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')
  SQL

  SELECT_MEAN_LOAN_DURATION_STMT = 'SELECT_MEAN_LOAN_DURATION'.freeze
  SELECT_MEAN_LOAN_DURATION = <<~SQL.freeze
    SELECT AVG(EXTRACT(EPOCH FROM loan_duration)) AS mean_loan_duration
      FROM (#{SELECT_ALL_LOAN_DURATIONS}) AS loan_durations
  SQL

  SELECT_MEDIAN_LOAN_DURATION_STMT = 'SELECT_MEDIAN_LOAN_DURATION'.freeze
  SELECT_MEDIAN_LOAN_DURATION = <<~SQL.freeze
    SELECT EXTRACT(EPOCH
                    FROM (PERCENTILE_CONT(0.5)
                         WITHIN GROUP (ORDER BY loan_duration))
                  ) AS median_loan_duration
      FROM (#{SELECT_ALL_LOAN_DURATIONS}) AS loan_durations
  SQL

  CSV_LOAN_COLS = %i[loan_date due_date return_date loan_status].freeze
  CSV_ITEM_COLS = %i[record_id barcode title author publisher physical_desc].freeze
  CSV_HEADERS = (CSV_LOAN_COLS + CSV_ITEM_COLS).map { |attr| attr.to_s.titleize }

  # ------------------------------------------------------------
  # Accessors

  attr_reader :item, :loans

  # ------------------------------------------------------------
  # Initializer

  def initialize(item, loans)
    @item = item
    @loans = loans
  end

  # ------------------------------------------------------------
  # Class methods

  class << self
    def all(&block)
      return to_enum(:all) unless block_given?

      each_by_date.map { |_, stats_for_date| stats_for_date.each(&block) }
    end

    def each_by_date
      return to_enum(:each_by_date) unless block_given?

      all_loan_dates.lazy.each { |date| yield [date, each_for_date(date)] }
    end

    def each_for_date(date)
      raise ArgumentError, "#{date.inspect} is not a date object" unless date.respond_to?(:to_date) && (date.to_date == date)
      return to_enum(:each_for_date, date) unless block_given?

      LendingItem
        .includes(:lending_item_loans)
        .joins(:lending_item_loans) # INNER JOIN
        .merge(LendingItemLoan.loaned_on(date))
        .find_each do |item|
        # TODO: get scoped eager loading working properly so we don't have to pass the scope twice
        # yield new(item, item.lending_item_loans)
        yield new(item, item.lending_item_loans.loaned_on(date))
      end
    end

    def all_loan_dates
      stmt = ActiveRecord::Base.sanitize_sql([SELECT_DISTINCT_LOAN_DATES, Time.zone.name])
      ActiveRecord::Base.connection
        .exec_query(stmt, SELECT_DISTINCT_LOAN_DATES_STMT, prepare: true)
        .rows
        .map { |row| Date.parse(row[0]) }
    end

    # for debugging
    def all_loan_dates_by_id
      stmt = ActiveRecord::Base.sanitize_sql([SELECT_LOAN_DATES_BY_ID, Time.zone.name])
      ActiveRecord::Base.connection
        .exec_query(stmt, SELECT_LOAN_DATES_BY_ID_STMT, prepare: true)
        .rows
        .map { |row| [row[0], Date.parse(row[1])] }
    end

    def median_loan_duration
      stmt = Arel.sql(SELECT_MEDIAN_LOAN_DURATION)
      ActiveRecord::Base.connection
        .exec_query(stmt, SELECT_MEDIAN_LOAN_DURATION_STMT, prepare: true)
        .first['median_loan_duration']
    end

    def mean_loan_duration
      stmt = Arel.sql(SELECT_MEAN_LOAN_DURATION)
      ActiveRecord::Base.connection
        .exec_query(stmt, SELECT_MEAN_LOAN_DURATION_STMT, prepare: true)
        .first['mean_loan_duration']
    end

  end

  # ------------------------------------------------------------
  # Stats methods

  def loan_count_total
    loans.size
  end

  def loan_count_by_status(loan_status)
    return 0 unless (loans_for_status = loans_by_status[loan_status])

    loans_for_status.size
  end

  def loan_counts_by_status
    @loan_counts_by_status ||= LendingItemLoan::LOAN_STATUS_SCOPES.each_with_object({}) do |scope, counts|
      next if (count = loan_count_by_status(scope)) == 0

      counts[scope] = count
    end
  end

  # ------------------------------------------------------------
  # Export

  def to_csv(out = nil)
    return StringIO.new.tap { |o| to_csv(o) }.string unless out

    loans.each do |loan|
      loan_cols = CSV_LOAN_COLS.map { |attr| loan.send(attr) }
      item_cols = CSV_ITEM_COLS.map { |attr| item.send(attr) }
      csv_line = CSV.generate_line(loan_cols + item_cols, encoding: 'UTF-8')
      out << csv_line
    end
  end

  # ------------------------------------------------------------
  # Comparable

  def <=>(other)
    return unless other.is_a?(ItemLendingStats)

    # sort from most to least
    order = other.loans.count <=> loans.count
    return order if order != 0

    0.tap do
      ItemLendingStats::CSV_ITEM_COLS.filter_map do |attr|
        attr_order = item.send(attr) <=> other.item.send(attr)
        return attr_order if attr_order != 0
      end
    end
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def loans_by_status
    @loans_by_status ||= {}.with_indifferent_access.tap do |lbs|
      LendingItemLoan::LOAN_STATUS_SCOPES.each { |scope| lbs[scope] = loans.send(scope) }
    end
  end
end
# rubocop:enable Metrics/ClassLength