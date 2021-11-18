# Ensure migration can run without error even if we delete/rename the models
class LendingItem < ActiveRecord::Base; end unless defined?(LendingItem)

class AddPubMetadataToLendingItems < ActiveRecord::Migration[6.0]
  def change
    add_column :lending_items, :publisher, :string
    add_column :lending_items, :physical_desc, :string

    LendingItem.reset_column_information
    LendingItem.find_each { |item| item.refresh_marc_metadata! }
  end
end
