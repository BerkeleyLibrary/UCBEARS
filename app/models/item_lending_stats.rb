class ItemLendingStats
  include Comparable

  # ------------------------------------------------------------
  # Constants

  STMT_NAME_ALL_LOAN_DATES = 'loan_dates'.freeze
  ALL_LOAN_DATES_SQL = <<~SQL.freeze
      SELECT DISTINCT DATE((loan_date AT TIME ZONE 'UTC') AT TIME ZONE ?)
        FROM lending_item_loans
    ORDER BY 1 DESC
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
    @loans = loans.is_a?(Array) ? loans : loans.to_a
  end

  # ------------------------------------------------------------
  # Class methods

  class << self
    def all_loan_dates
      stmt = ActiveRecord::Base.sanitize_sql([ALL_LOAN_DATES_SQL, Time.zone.name])
      ActiveRecord::Base.connection
        .exec_query(stmt, STMT_NAME_ALL_LOAN_DATES)
        .rows
        .map { |row| Date.parse(row[0]) }
    end

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

      lending_items_with_loans_on(date)
        .find_each { |item| yield new(item, item.lending_item_loans) }
    end

    private

    def lending_items_with_loans_on(date)
      LendingItem
        .includes(:lending_item_loans)
        .joins(:lending_item_loans) # INNER JOIN
        .where(
          'lending_item_loans.loan_date >= ? AND lending_item_loans.loan_date < ?',
          date.to_time,
          (date + 1.days).to_time
        )
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

  def loan_counts_by_state
    @loan_counts_by_state ||= LendingItemLoan::LOAN_STATES.each_with_object({}) do |state, counts|
      next if (count = loan_count_by_status(state)) == 0

      counts[state] = count
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
      loans.each { |loan| (lbs[loan.loan_status] ||= []) << loan }
    end
  end
end
