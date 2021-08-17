class AddEmailToProxyBorrowerRequest < ActiveRecord::Migration[5.2]
  def change
    add_column :proxy_borrower_requests, :user_email, :string
  end
end
