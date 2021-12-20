require 'rails_helper'

RSpec.describe Term, type: :model do
  describe :create do
    it 'requires a name' do
      term = Term.create(start_date: Date.current, end_date: Date.current + 1.days)
      expect(term).not_to be_valid
      expect(term).not_to be_persisted
    end

    it 'requires start date to be before end date' do
      term = Term.create(start_date: Date.current, end_date: Date.current - 1.days)
      expect(term).not_to be_valid
      expect(term).not_to be_persisted
    end
  end
end
