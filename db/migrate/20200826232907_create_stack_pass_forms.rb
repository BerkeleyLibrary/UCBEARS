class CreateStackPassForms < ActiveRecord::Migration[5.2]
  def change
    create_table :stack_pass_forms do |t|
      t.string :email
      t.string :name
      t.string :phone
      t.datetime :pass_date
      t.boolean :main_stack
      t.string :local_id
      t.datetime :time_requested
      t.boolean :approved
      t.string :approved_by
      t.datetime :time_approved
      t.integer :denial_reason
      t.boolean :archived
      t.timestamps
    end
  end
end
