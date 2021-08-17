class RemoveProcessedFromLendingItems < ActiveRecord::Migration[6.0]
  def change
    remove_column :lending_items, :processed, :boolean
  end
end
