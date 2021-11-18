# Ensure migration can run without error even if we delete/rename the models
class LendingItemLoan < ActiveRecord::Base; end unless defined?(LendingItemLoan)

class ClearInvalidReturnDates < ActiveRecord::Migration[6.0]
  def change
    LendingItemLoan.where('return_date > due_date').update_all(return_date: nil)
  end
end
