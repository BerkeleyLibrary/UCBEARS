class CreateLendingItemLoans < ActiveRecord::Migration[6.0]
  def change
    create_table :lending_item_loans do |t|
      t.references :lending_item, null: false, foreign_key: true
      t.string :patron_identifier
      t.string :loan_status, default: 'pending'
      t.datetime :loan_date
      t.datetime :due_date
      t.datetime :return_date

      t.timestamps
    end
    add_index :lending_item_loans, :patron_identifier
  end
end
