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

    it 'coerces dates to local date' do
      start_date = Date.new(2021, 8, 18)
      end_date = Date.new(2021, 12, 17)
      expected_start_date = Date.new(2021, 8, 18)
      expected_end_date = Date.new(2021, 12, 17)
      term = Term.create(name: 'Fall 2021', start_date: start_date, end_date: end_date)
      expect(term).to be_valid # just to be sure
      expect(term).to be_persisted # just to be sure

      expect(term.start_date).to eq(expected_start_date)
      expect(term.end_date).to eq(expected_end_date)
    end

    it 'coerces times to date' do
      start_date = Time.zone.local(2021, 8, 18)
      end_date = Time.zone.local(2021, 12, 17, 23, 59, 59)
      expected_start_date = Date.new(2021, 8, 18)
      expected_end_date = Date.new(2021, 12, 17)
      term = Term.create(name: 'Fall 2021', start_date: start_date, end_date: end_date)
      expect(term).to be_valid # just to be sure
      expect(term).to be_persisted # just to be sure

      expect(term.start_date).to eq(expected_start_date)
      expect(term.end_date).to eq(expected_end_date)
    end
  end

  describe :current do
    it 'includes the currently active term' do
      term = create(:term, name: 'Test 1', start_date: Date.current - 1.days, end_date: Date.current + 1.days)
      expect(term).to be_persisted # just to be sure

      expect(term).to be_current
      expect(Term.current).to include(term)
    end

    it 'is empty if there is no currently active term' do
      term = create(:term, name: 'Test 1', start_date: Date.current - 3.days, end_date: Date.current - 1.days)
      expect(term).to be_persisted # just to be sure

      expect(term).not_to be_current
      expect(Term.current).not_to exist
    end

    it 'is inclusive' do
      past_term = create(:term, name: 'Test 0', start_date: Date.current - 3.days, end_date: Date.current - 2.days)
      expect(past_term).not_to be_current

      current_terms = [
        create(:term, name: 'Test 1', start_date: Date.current, end_date: Date.current + 1.days),
        create(:term, name: 'Test 2', start_date: Date.current - 1.days, end_date: Date.current)
      ]
      current_terms.each { |t| expect(t).to be_current }

      future_term = create(:term, name: 'Test 4', start_date: Date.current + 2.days, end_date: Date.current + 3.days)
      expect(future_term).not_to be_current

      expect(Term.current).to contain_exactly(*current_terms)

      expect(Term.current).not_to include(past_term)
      expect(Term.current).not_to include(future_term)
    end
  end
end
