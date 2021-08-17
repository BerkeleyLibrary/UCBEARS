class LendingClearInvalidRecords < ActiveRecord::Migration[6.0]
  def change
    LendingItem.where("directory LIKE '%.pdf'").destroy_all
  end
end
