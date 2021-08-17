class CreateProxyBorrowerUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :proxy_borrower_users do |t|
      t.integer :lcasid, null: false
      t.string :name, null: false
      t.string :role, null: false
      t.string :email, null: false
    end
  end
end
