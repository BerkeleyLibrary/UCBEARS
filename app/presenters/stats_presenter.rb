require 'ostruct'

# TODO: Rewrite as helper methods? or as a model?
class StatsPresenter

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

  def loan_count_returned
    LendingItemLoan.returned.count
  end

  def loan_count_expired
    LendingItemLoan.expired.count
  end

  def loan_count_complete
    LendingItemLoan.complete.count
  end

  def loan_duration_median
    ItemLendingStats.median_loan_duration
  end

  def loan_duration_avg
    ItemLendingStats.mean_loan_duration
  end

  # ------------------------------------------------------------
  # Item stats

  def item_counts_by_state
    # TODO: use Rails i18n
    {
      inactive: 'New or inactive',
      active: 'Active',
      incomplete: 'Incomplete'
    }.each_with_object({}) do |(scope, title), counts|
      counts[title] = Item.send(scope).count
    end
  end

  def item_lending_stats_by_date
    ItemLendingStats.each_by_date.map do |date, stats|
      [date, stats.sort]
    end
  end
end
