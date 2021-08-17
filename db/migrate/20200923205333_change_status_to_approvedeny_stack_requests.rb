class ChangeStatusToApprovedenyStackRequests < ActiveRecord::Migration[5.2]
  def change
    rename_column :stack_requests, :status, :approvedeny
  end
end
