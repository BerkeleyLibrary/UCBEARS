class AddIIIFDirToLendingItems < ActiveRecord::Migration[6.0]
  def change
    add_column :lending_items, :iiif_dir, :string
  end
end
