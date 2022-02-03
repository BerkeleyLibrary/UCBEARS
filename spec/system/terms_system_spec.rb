require 'rails_helper'

describe TermsController, type: :system do
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

  def updated_at_str(term)
    tz_js = page.evaluate_script('Intl.DateTimeFormat().resolvedOptions().timeZone')
    updated_at = term.updated_at
    updated_at_tz = updated_at.in_time_zone(tz_js)

    # DateTime#strftime translation of the format we're using in JS
    datetime_fmt = '%Y-%m-%d %-l:%M %p'.freeze
    updated_at_tz.strftime(datetime_fmt)
  end

  def name_field_id(term)
    "term-#{term.id}-name"
  end

  def delete_button_id(term)
    "term-#{term.id}-delete"
  end

  def expect_name_field(term)
    expect(page).to have_field(name_field_id(term), type: 'text', with: term.name)
  end

  def expect_no_name_field(term)
    expect(page).not_to have_field(name_field_id(term), type: 'text', with: term.name)
  end

  def expect_updated_at(term)
    expect(page).to have_content(updated_at_str(term))
  end

  def expect_no_updated_at(term)
    expect(page).not_to have_content(updated_at_str(term))
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

      describe 'delete' do
        attr_reader :term

        before(:each) do
          @term = Term.take
        end

        it 'deletes a term' do
          expect(term.items).to be_empty # just to be sure

          button = page.find_button(delete_button_id(term))
          button.click

          expect_no_name_field(term)
          expect(Term.exists?(term.id)).to eq(false)
        end

        describe 'with items' do
          attr_reader :item

          before(:each) do
            expect(term.items).to be_empty # just to be sure

            @item = Item.take
            item.terms << term
            expect(term.items).to include(item) # just to be sure

            # Refresh page
            visit terms_path
          end

          it 'requires confirmation' do
            button = page.find_button(delete_button_id(term))
            accept_confirm do
              button.click
            end
            expect_no_name_field(term)
            expect(Term.exists?(term.id)).to eq(false)
            expect(item.terms).not_to exist
          end

          it 'can be cancelled' do
            button = page.find_button(delete_button_id(term))

            # TODO: why doesn't dismiss_confirm work?
            page.dismiss_confirm do
              button.click
            end

            expect_name_field(term)
            expect(Term.exists?(term.id)).to eq(true)
            expect(item.terms).to include(term)
          end
        end

      end
    end
  end
end
