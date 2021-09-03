class AddLoanStatusIndexToLendingItemLoans < ActiveRecord::Migration[6.0]
  def change
    add_index(:lending_item_loans, [:lending_item_id, :loan_status], name: 'lending_item_loan_status')
  end
end
