class CreateTerms < ActiveRecord::Migration[6.1]
  def change
    create_table :terms do |t|
      t.string :name, null: false, index: { unique: true }
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end
  end
end
