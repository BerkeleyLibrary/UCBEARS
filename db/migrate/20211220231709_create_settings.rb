# Ensure migration can run without error even if we delete/rename the models
class Settings < ActiveRecord::Base; end unless defined?(Settings)
class Term < ActiveRecord::Base; end unless defined?(Term)

class CreateSettings < ActiveRecord::Migration[6.1]
  SPRING_2021 = '2021 Spring Semester'

  def up
    create_table :settings do |t|
      t.references :default_term, null: true, foreign_key: { to_table: :terms }

      t.timestamps
    end

    change_table(:settings) { |t| t.change :id, :integer, default: 1 }

    execute <<~SQL
      ALTER TABLE settings
      ADD CONSTRAINT max_one_settings_row CHECK (id = 1)
    SQL

    spring_2021 = Term.find_by(name: SPRING_2021)
    Settings.create!(default_term: spring_2021)
  end

  def down
    drop_table :settings
  end
end
