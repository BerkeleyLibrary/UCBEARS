# Ensure migration can run without error even if we delete/rename the models
class LendingItem < ActiveRecord::Base; end unless defined?(LendingItem)

class LoadMissingMarcMetadata < ActiveRecord::Migration[6.0]
  def change
    LendingItem.where(publisher: nil).or(LendingItem.where(physical_desc: nil)).find_each do |item|
      item.refresh_marc_metadata!
    end
  end
end
