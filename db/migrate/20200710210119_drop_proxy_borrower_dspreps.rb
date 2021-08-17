class DropProxyBorrowerDspreps < ActiveRecord::Migration[5.2]
  def change
    drop_table :proxy_borrower_dspreps
  end
end
