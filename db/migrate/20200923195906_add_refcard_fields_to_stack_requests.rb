class AddRefcardFieldsToStackRequests < ActiveRecord::Migration[5.2]
  def change
    # Changing this to work for both Stack Pass and Ref Card so need type:
    add_column :stack_requests, :type, :string

    # These cols are needed for Ref Card
    add_column :stack_requests, :affiliation, :string
    add_column :stack_requests, :research_desc, :text
    add_column :stack_requests, :pass_date_end, :date

    # Shouldn't have been a datetime - change to date:
    change_column :stack_requests, :pass_date, :date
    
    # These were in the original app, not needed here:
    remove_column :stack_requests, :archived
    remove_column :stack_requests, :time_approved
    
    # Use of these columns changed slightly so renaming:
    rename_column :stack_requests, :approved, :status
    rename_column :stack_requests, :approved_by, :processed_by
  end
end
