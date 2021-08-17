class ChangeProxyBorrowerUsersEmail < ActiveRecord::Migration[5.2]
  def change
    change_column_null :proxy_borrower_users, :email, true
  end
end
