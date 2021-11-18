class RenameLendingItemLoansToLoans < ActiveRecord::Migration[6.1]
  def change
    rename_table :lending_item_loans, :loans
  end
end
