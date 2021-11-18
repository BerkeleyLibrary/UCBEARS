class RenameLendingItemsToItems < ActiveRecord::Migration[6.1]
  def change
    rename_table :lending_items, :items
    rename_column :lending_item_loans, :lending_item_id, :item_id
  end
end
