class StatsPresenter
  def session_unique_users
    SessionCounter.count('DISTINCT uid') # TODO: what's the ActiveRecord syntax for this?
  end

  def session_count_total
    SessionCounter.sum(:count)
  end

  def session_counts_by_type
    %i[student staff faculty admin].map do |type|
      sum_for_type = SessionCounter.where(type => true).sum(:count)
      [type, sum_for_type]
    end.to_h
  end

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
    expr = 'EXTRACT(EPOCH from (return_date - loan_date))'
    LendingItemLoan.complete.pluck(Arel.sql(expr))
  end

  def loan_duration_median
    sorted = loan_durations.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def loan_duration_avg
    expr = 'AVG(EXTRACT(EPOCH from (return_date - loan_date)))'
    LendingItemLoan.complete.pluck(Arel.sql(expr)).first
  end
end
