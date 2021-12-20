class CreateJoinTableItemTerm < ActiveRecord::Migration[6.1]
  def change
    create_join_table :items, :terms do |t|
      t.index [:item_id, :term_id]
      t.index [:term_id, :item_id]
    end
  end
end
