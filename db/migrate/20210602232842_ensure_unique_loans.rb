class EnsureUniqueLoans < ActiveRecord::Migration[6.0]
  FIELDS = [:lending_item_id, :patron_identifier, :loan_status]

  def change
    add_index(:lending_item_loans, FIELDS, unique: true, name: 'lending_item_loan_uniqueness')
  end
end
