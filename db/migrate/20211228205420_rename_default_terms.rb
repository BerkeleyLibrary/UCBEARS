# Ensure migration can run without error even if we delete/rename the models
class Term < ActiveRecord::Base; end unless defined?(Term)

class RenameDefaultTerms < ActiveRecord::Migration[6.1]
  OLD_TO_NEW = {
    '2021 Fall Semester'.freeze => 'Fall 2021'.freeze,
    # oops
    '2021 Spring Semester'.freeze => 'Spring 2022'.freeze
  }.freeze

  def up
    OLD_TO_NEW.each do |old_name, new_name|
      next unless (term = Term.find_by(name: old_name))

      term.update(name: new_name)
    end
  end

  def down
    OLD_TO_NEW.each do |old_name, new_name|
      next unless (term = Term.find_by(name: new_name))

      term.update(name: old_name)
    end
  end
end
