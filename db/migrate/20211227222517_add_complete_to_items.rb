# Ensure migration can run without error even if we delete/rename the models
class Item < ActiveRecord::Base; end unless defined?(Item)

class AddCompleteToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :complete, :boolean, null: false, default: false

    Item.find_each do |item|
      directory_complete = IIIFDirectory.new(item.directory).complete?
      item.update(complete: directory_complete)
    end
  end
end
