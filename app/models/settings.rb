class Settings < ApplicationRecord
  belongs_to :default_term, class_name: 'Term', optional: true

  class << self
    def instance
      Settings.take || Settings.create!
    end

    delegate :default_term, to: :instance

    def default_term=(value)
      instance.update!(default_term: value)
    end
  end
end
