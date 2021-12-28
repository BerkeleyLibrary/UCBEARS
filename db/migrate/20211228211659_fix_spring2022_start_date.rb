# Ensure migration can run without error even if we delete/rename the models
class Term < ActiveRecord::Base; end unless defined?(Term)

class FixSpring2022StartDate < ActiveRecord::Migration[6.1]
  def up
    return unless (term = Term.find_by(name: 'Spring 2022'))

    term.update(start_date: Date.new(2022, 1, 11))
  end

  def down
    return unless (term = Term.find_by(name: 'Spring 2022'))

    term.update(start_date: Date.new(2022, 1, 22))
  end
end
