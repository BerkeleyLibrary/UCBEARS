# Ensure migration can run without error even if we delete/rename the models
class Term < ActiveRecord::Base; end unless defined?(Term)
class Item < ActiveRecord::Base; end unless defined?(Item)

class SetDefaultTerms < ActiveRecord::Migration[6.1]
  FALL_2021 = '2021 Fall Semester'
  SPRING_2021 = '2021 Spring Semester' # oops; fixed in RenameDefaultTerms

  def up
    fall_2021 = Term.create!(name: FALL_2021, start_date: Date.new(2021, 8, 18), end_date: Date.new(2021, 12, 17))
    _spring_2022 = Term.create!(name: SPRING_2021, start_date: Date.new(2022, 1, 22), end_date: Date.new(2022, 5, 13))

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
    [FALL_2021, SPRING_2021].each do |term_name|
      next unless (term = Term.find_by(name: term_name))

      term.items.clear
      term.destroy!
    end
  end
end
