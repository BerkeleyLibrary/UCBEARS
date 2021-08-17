class RemoveTimeRequestedFromStackPassForms < ActiveRecord::Migration[5.2]
  def change
    remove_column :stack_pass_forms, :time_requested
  end
end
