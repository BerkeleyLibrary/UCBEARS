class CreateSessionCounters < ActiveRecord::Migration[6.0]
  def change
    create_table :session_counters do |t|
      t.string :uid
      t.boolean :student
      t.boolean :staff
      t.boolean :faculty
      t.boolean :admin
      t.integer :count
    end
  end
end
