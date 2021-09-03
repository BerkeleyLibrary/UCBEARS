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
  # Comparable

  def <=>(other)
    return unless other.is_a?(ItemLendingStats)

    # sort from most to least
    order = other.loans.count <=> loans.count
    return order if order != 0

    order = item.title <=> other.item.title
    return order if order != 0

    item.directory <=> other.item.directory
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
