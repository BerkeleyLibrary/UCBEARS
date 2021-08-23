# Ensure migration can run without error even if we delete/rename the models
class LendingItem < ActiveRecord::Base; end unless defined?(LendingItem)

class LendingClearInvalidRecords < ActiveRecord::Migration[6.0]
  def change
    LendingItem.where("directory LIKE '%.pdf'").destroy_all
  end
end
