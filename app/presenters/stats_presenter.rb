require 'ostruct'

# TODO: Rewrite as helper methods? or as a model?
class StatsPresenter

  # ------------------------------------------------------------
  # Constants

  LOAN_STATS_SQL = <<~SQL.freeze
      SELECT lending_items.id,
             lending_items.directory,
             lending_items.title,
             lending_items.author,
             lending_items.publisher,
             lending_items.physical_desc,
             loan_counts.loan_status,
             loan_counts.loan_count,
             loan_counts.loan_date
        FROM lending_items,
             (
                 SELECT loan_status,
                        COUNT(id) AS loan_count,
                        DATE(loan_date) AS loan_date,
                        lending_item_id
                   FROM lending_item_loans
                  WHERE DATE(loan_date) = ?
               GROUP BY DATE(loan_date), loan_status, lending_item_id
             ) AS loan_counts
       WHERE (loan_counts.lending_item_id = lending_items.id)
    ORDER BY lending_items.title,
             loan_counts.loan_status,
             loan_counts.loan_count
  SQL

  LOAN_DURATIONS_SQL = 'EXTRACT(EPOCH from (return_date - loan_date))'.freeze
  LOAN_DURATION_AVG_SQL = 'AVG(EXTRACT(EPOCH from (return_date - loan_date)))'.freeze

  # ------------------------------------------------------------
  # Session stats

  def session_unique_users
    # TODO: do we care if UIDs occur multiple times with different flags?
    all_session_stats.reduce(0) { |total, stat| total + stat.unique_users }
  end

  def session_count_total
    all_session_stats.reduce(0) { |total, stat| total + stat.total_sessions }
  end

  def all_session_stats
    @session_stats ||= SessionStats.all.to_a.sort
  end

  # ------------------------------------------------------------
  # Loan stats

  def loan_count_total
    LendingItemLoan.count
  end

  def loan_count_active
    LendingItemLoan.active.count
  end

  def loan_count_complete
    LendingItemLoan.complete.count
  end

  def loan_count_expired
    LendingItemLoan.complete.where('return_date >= due_date').count
  end

  def loan_durations
    expr = Arel.sql(LOAN_DURATIONS_SQL)
    LendingItemLoan.complete.pluck(expr)
  end

  def loan_duration_median
    sorted = loan_durations.sort
    return if sorted.empty?

    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def loan_duration_avg
    expr = Arel.sql(LOAN_DURATION_AVG_SQL)
    LendingItemLoan.complete.pluck(expr).first
  end

  # ------------------------------------------------------------
  # Item stats

  def item_counts_by_state
    # TODO: use Rails i18n
    state_to_title = {
      inactive: 'New or inactive items',
      active: 'Active items',
      incomplete: 'Incomplete items'
    }
    # TODO: don't load all items just to do this
    state_to_title.map do |state, state_title|
      [state_title, LendingItem.send(state).count]
    end.to_h
  end

  def item_lending_stats_by_date
    ItemLendingStats.each_by_date.map do |date, stats|
      [date, stats.sort]
    end
  end
end
