class SimplifyLendingItems < ActiveRecord::Migration[6.0]
  DROPPED_COLUMNS = [:millennium_record, :alma_record, :barcode, :iiif_dir]

  def up
    remove_index(:lending_items, name: 'lending_item_uniqueness')
    rename_column(:lending_items, :filename, :directory)

    add_column(:lending_items, :processed, :boolean)
    LendingItem.where.not(iiif_dir: nil).update_all(processed: true)

    remove_columns(:lending_items, *DROPPED_COLUMNS)

    add_index(:lending_items, :directory, unique: true)
  end

  def down
    remove_index(:lending_items, column: :directory)

    DROPPED_COLUMNS.each { |col| add_column(:lending_items, col, :string) }

    LendingItem.where(processed: true).update_all('iiif_dir=directory')
    remove_column(:lending_items, :processed)

    rename_column(:lending_items, :directory, :filename)
    LendingItem.find_each(&method(:split_barcode))

    add_index(:lending_items, [:barcode, :filename], unique: true, name: 'lending_item_uniqueness')
  end

  private

  def split_barcode(item)
    record_id, item.barcode = item.filename.split('_')
    if record_id.start_with?('b')
      item.millennium_record = record_id
    else
      item.alma_record = record_id
    end
    item.save!
  end

end
