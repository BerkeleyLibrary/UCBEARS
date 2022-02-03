require 'rails_helper'

describe TermsController, type: :system do
  # DateTime#strftime translation of the format we're using in JS
  let(:datetime_fmt) { '%Y-%m-%d %-l:%M %p'.freeze }

  attr_reader :terms_by_time

  before(:each) do
    @terms_by_time = %w[past current future].each_with_object({}) do |time, terms|
      term = create("term_#{time}")

      # Hack timestamps for ease of testing
      term.created_at = term.start_date - 6.months
      term.updated_at = term.created_at
      term.save(touch: false)

      terms[time] = term
    end
  end

  def name_field_id(term)
    "term-#{term.id}-name"
  end

  def expect_name_field(term)
    expect(page).to have_field(name_field_id(term), type: 'text', with: term.name)
  end

  def expect_no_name_field(term)
    expect(page).not_to have_field(name_field_id(term), type: 'text', with: term.name)
  end

  def expect_updated_at(term)
    expect(page).to have_content(term.updated_at.strftime(datetime_fmt))
  end

  def expect_no_updated_at(term)
    expect(page).not_to have_content(term.updated_at.strftime(datetime_fmt))
  end

  context 'with lending admin credentials' do
    before(:each) { mock_login(:lending_admin) }
    after(:each) { logout! }

    describe :index do
      before(:each) do
        visit terms_path
      end

      it 'displays the terms' do
        Term.find_each do |term|
          expect_name_field(term)
          expect_updated_at(term)
        end
      end

      it 'filters by past/current/future' do
        checked = []

        terms_by_time.each_key do |time|
          page.check("termFilter-#{time}")
          checked << time

          expected_terms = checked.map { |t| terms_by_time[t] }
          deselected_terms = Term.where.not(id: expected_terms.map(&:id))

          expected_terms.each { |t| expect_name_field(t) }
          deselected_terms.each { |t| expect_no_name_field(t) }
        end

        terms_by_time.keys.reverse_each do |time|
          page.uncheck("termFilter-#{time}")
          checked.delete(time)

          expected_terms = checked.empty? ? Term.all : checked.map { |t| terms_by_time[t] }
          deselected_terms = Term.where.not(id: expected_terms.map(&:id))

          expected_terms.each { |t| expect_name_field(t) }
          deselected_terms.each { |t| expect_no_name_field(t) }
        end
      end

      it 'allows editing a term name' do
        term = Term.take
        name_field = page.find_field(name_field_id(term), type: 'text')

        new_name = "New name for #{term.name}"
        name_field.fill_in(with: new_name, fill_options: { clear: :backspace })
        page.find('body').click # trigger blur event
        expect_no_updated_at(term) # wait for updated_at to change

        term.reload
        expect(term.name).to eq(new_name)
        expect_updated_at(term)
      end
    end
  end
end
