# Ensure migration can run without error even if we delete/rename the models
class LendingItemLoan < ActiveRecord::Base; end unless defined?(LendingItemLoan)

class RemoveLoanStatusFromLendingItemLoans < ActiveRecord::Migration[6.0]
  def up
    remove_index :lending_item_loans, name: 'lending_item_loan_status'
    remove_index :lending_item_loans, name: 'lending_item_loan_uniqueness'
    remove_column :lending_item_loans, :loan_status, :string
  end

  def down
    add_column :lending_item_loans, :loan_status, :string

    LendingItemLoan.where('loan_date IS NULL').update_all(loan_status: 'pending')

    # NOTE: This is subtly different fro the :active scope that replaces it,
    #       as previous to this migration loans were considered active until
    #       auto-returned
    LendingItemLoan.where('return_date IS NULL AND loan_date IS NOT NULL')
      .update_all(loan_status: 'active')

    # NOTE: This is subtly different from the :complete scope that replaces
    #       this status, as previous to this migration the return_date was always
    #       set even when expired items were auto-returned
    LendingItemLoan.where('return_date IS NOT NULL')
      .update_all(loan_status: 'complete')

    add_index(:lending_item_loans, FIELDS, where: "loan_status = 'active'", unique: true, name: INDEX_NAME)
    add_index(:lending_item_loans, [:lending_item_id, :loan_status], name: 'lending_item_loan_status')
  end
end
