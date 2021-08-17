class ChangeProxyBorrowerRequestsFacultyName < ActiveRecord::Migration[5.2]
  def change
    change_column_null :proxy_borrower_requests, :faculty_name, true
  end
end
