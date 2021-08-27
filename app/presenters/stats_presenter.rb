# TODO: Rewrite as helper methods? or as a model?
class StatsPresenter

  # ------------------------------------------------------------
  # Session stats

  def session_unique_users
    SessionCounter.count('DISTINCT uid') # TODO: what's the ActiveRecord syntax for this?
  end

  def session_count_total
    SessionCounter.sum(:count)
  end

  def session_counts_by_type
    %i[admin staff faculty student].map do |type|
      sum_for_type = SessionCounter.where(type => true).sum(:count)
      [type, sum_for_type]
    end.to_h
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
    expr = Arel.sql('EXTRACT(EPOCH from (return_date - loan_date))')
    LendingItemLoan.complete.pluck(expr)
  end

  def loan_duration_median
    sorted = loan_durations.sort
    return if sorted.empty?

    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def loan_duration_avg
    expr = Arel.sql('AVG(EXTRACT(EPOCH from (return_date - loan_date)))')
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

  def checkouts_by_item
    # TODO: something more efficient, w/nil handling
    LendingItemLoan
      .joins(:lending_item)
      .group(:lending_item_id)
      .count(:lending_item_id)
      .sort_by { |_, ct| -ct }
      .to_h
  end

  def active_checkouts_by_item
    # TODO: something more efficient, w/nil handling
    LendingItemLoan
      .active
      .joins(:lending_item)
      .group(:lending_item_id)
      .count(:lending_item_id)
      .sort_by { |_, ct| -ct }
      .to_h
  end
end
