# Ensure migration can run without error even if we delete/rename the models
class LendingItemLoan < ActiveRecord::Base; end unless defined?(LendingItemLoan)

class ClearPrereleaseLendingHistory < ActiveRecord::Migration[6.0]
  def change
    cond = Arel.sql('INNER JOIN session_counters ON session_counters.uid = lending_item_loans.patron_identifier')
    LendingItemLoan.where(loan_status: 'complete').joins(cond).destroy_all
  end
end
