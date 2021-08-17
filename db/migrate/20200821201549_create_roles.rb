class CreateRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :roles do |t|
      t.string "role", null: false
      t.timestamps
    end
  end
end
