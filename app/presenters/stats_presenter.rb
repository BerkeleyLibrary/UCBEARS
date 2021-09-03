require 'ostruct'

# TODO: Rewrite as helper methods? or as a model?
class StatsPresenter

  # ------------------------------------------------------------
  # Constants

  SESSION_COUNTS_BY_TYPE_SQL = <<~SQL.freeze
      SELECT student, staff, faculty, admin,
             SUM(count) AS total_sessions,
             count(DISTINCT uid) AS unique_users#{' '}
        FROM session_counters
       WHERE uid IS NOT NULL
    GROUP BY (student, staff, faculty, admin)
  SQL

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
    SessionCounter.count('DISTINCT uid') # TODO: what's the ActiveRecord syntax for this?
  end

  def session_count_total
    SessionCounter.sum(:count)
  end

  def session_counts_by_type
    stmt = Arel.sql(SESSION_COUNTS_BY_TYPE_SQL)

    ActiveRecord::Base.connection.execute(stmt).each_with_object({}) do |result, counts|
      types = %w[student staff faculty admin].select { |t| result[t] }.sort
      next if types.empty? # should never happen

      counts[types] = { total_sessions: result['total_sessions'], unique_users: result['unique_users'] }
    end
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

  def loan_stats_by_date
    # TODO: single query w/cursor?
    LendingItemLoan.distinct.order('date(loan_date) desc').pluck('date(loan_date)').lazy.map { |d| [d, loan_stats_for_date(d)] }
  end

  def loan_stats_for_date(loan_date)
    # TODO: prepared statements instead of sanitize_sql?
    stmt = ActiveRecord::Base.sanitize_sql([LOAN_STATS_SQL, loan_date])
    # TODO: consider using postgresql_cursor gem
    #       see https://github.com/afair/postgresql_cursor
    ActiveRecord::Base.connection.execute(stmt).lazy.map { |row| OpenStruct.new(row) }
  end
end
