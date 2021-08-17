class RenameProxyBorrowerUsersToFrameworkUsers < ActiveRecord::Migration[5.2]
  def change
    rename_table :proxy_borrower_users, :framework_users
  end
end
