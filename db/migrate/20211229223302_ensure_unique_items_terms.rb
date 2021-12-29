class EnsureUniqueItemsTerms < ActiveRecord::Migration[6.1]
  def change
    remove_index :items_terms, column: [:item_id, :term_id]
    remove_index :items_terms, column: [:term_id, :item_id]

    # see https://stackoverflow.com/a/46775289/27358
    stmt = <<~SQL
      DELETE FROM items_terms t1
            USING items_terms t2
            WHERE t1.CTID > t2.CTID
              AND t1.item_id = t2.item_id
              AND t1.term_id = t2.term_id
    SQL
    exec_delete(stmt)

    add_index :items_terms, [:item_id, :term_id], unique: true
    add_index :items_terms, [:term_id, :item_id], unique: true

    add_foreign_key :items_terms, :items
    add_foreign_key :items_terms, :terms
  end
end
