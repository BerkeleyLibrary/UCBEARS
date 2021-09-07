class ClearInvalidReturnDates < ActiveRecord::Migration[6.0]
  def change
    LendingItemLoan.where('return_date > due_date').update_all(return_date: nil)
  end
end
