# Ensure migration can run without error even if we delete/rename the models
class LendingItem < ActiveRecord::Base; end unless defined?(LendingItem)

class AddActiveToLendingItems < ActiveRecord::Migration[6.0]
  def change
    add_column(:lending_items, :active, :boolean, null: false, default: false)

    LendingItem.where('copies > 0').update_all(active: true)
  end
end
