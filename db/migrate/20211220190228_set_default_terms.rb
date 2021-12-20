# Ensure migration can run without error even if we delete/rename the models
class Term < ActiveRecord::Base; end unless defined?(Term)
class Item < ActiveRecord::Base; end unless defined?(Item)

class SetDefaultTerms < ActiveRecord::Migration[6.1]
  def up
    fall_2021 = Term.create!(name: '2021 Fall Semester', start_date: Date.new(2021, 8, 18), end_date: Date.new(2021, 12, 17))
    _spring_2022 = Term.create!(name: '2021 Spring Semester', start_date: Date.new(2022, 1, 22), end_date: Date.new(2022, 5, 13))

    insert_stmt = <<~SQL
      INSERT INTO items_terms (item_id, term_id)
      SELECT orphaned_items.id, ?
        FROM (
              SELECT id
                FROM items
              EXCEPT (
                      SELECT item_id
                        FROM items_terms
                     )
             ) orphaned_items
    SQL

    sql = ActiveRecord::Base.sanitize_sql([insert_stmt, fall_2021.id])
    exec_insert(sql)
  end

  def down
    ['2021 Fall Semester', '2021 Spring Semester'].each do |term_name|
      next unless (term = Term.find_by(name: term_name))

      term.items.clear
      term.destroy!
    end
  end
end
