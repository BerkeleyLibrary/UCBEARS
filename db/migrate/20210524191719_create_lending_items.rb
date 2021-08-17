class CreateLendingItems < ActiveRecord::Migration[6.0]
  def change
    create_table :lending_items do |t|
      t.string :barcode
      t.string :filename
      t.string :title
      t.string :author
      t.string :millennium_record
      t.string :alma_record
      t.integer :copies

      t.timestamps
    end
  end
end
