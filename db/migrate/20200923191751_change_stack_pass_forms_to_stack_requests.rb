class ChangeStackPassFormsToStackRequests < ActiveRecord::Migration[5.2]
  def change
    rename_table :stack_pass_forms, :stack_requests
  end
end
