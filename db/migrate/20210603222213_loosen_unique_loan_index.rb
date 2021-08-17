class LoosenUniqueLoanIndex < ActiveRecord::Migration[6.0]
  FIELDS = [:lending_item_id, :patron_identifier]
  INDEX_NAME = 'lending_item_loan_uniqueness'

  def change
    remove_index(:lending_item_loans, name: INDEX_NAME)
    add_index(:lending_item_loans, FIELDS, where: "loan_status = 'active'", unique: true, name: INDEX_NAME)
  end
end
