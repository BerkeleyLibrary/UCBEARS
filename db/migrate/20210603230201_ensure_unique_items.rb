class EnsureUniqueItems < ActiveRecord::Migration[6.0]
  FIELDS = [:barcode, :filename]

  def change
    add_index(:lending_items, FIELDS, unique: true, name: 'lending_item_uniqueness')
  end
end
