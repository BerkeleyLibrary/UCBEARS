require 'rails_helper'

describe TermsController, type: :system do
  attr_reader :terms_by_time

  before do
    @terms_by_time = %w[past current future].each_with_object({}) do |time, terms|
      term = create("term_#{time}")

      # Hack timestamps for ease of testing
      term.created_at = term.start_date - 6.months
      term.updated_at = term.created_at
      term.save(touch: false)

      terms[time] = term
    end

    @prev_default_term = Settings.default_term
  end

  after do
    Settings.default_term = @prev_default_term
  end

  # TODO: share code w/other system specs
  def find_alerts
    page.find('aside#flash')
  end

  def find_alert(lvl)
    alerts = find_alerts
    alerts.find("div.#{lvl}")
  end

  # TODO: make this work with multiple alerts at same level
  def expect_alert(lvl, msg)
    alert = find_alert(lvl)
    expect(alert).to have_text(msg)
  end

  def updated_at_str(term)
    tz_js = page.evaluate_script('Intl.DateTimeFormat().resolvedOptions().timeZone')
    updated_at = term.updated_at
    updated_at_tz = updated_at.in_time_zone(tz_js)

    # DateTime#strftime translation of the format we're using in JS
    datetime_fmt = '%Y-%m-%d %-l:%M %p'.freeze
    updated_at_tz.strftime(datetime_fmt)
  end

  def row_id(term)
    "term-#{term.id}"
  end

  def default_checkbox_id(term)
    "term-#{term.id}-default_term"
  end

  def name_field_id(term)
    "term-#{term.id}-name"
  end

  def start_date_field_id(term)
    "term-#{term.id}-start-date"
  end

  def end_date_field_id(term)
    "term-#{term.id}-end-date"
  end

  def delete_button_id(term)
    "term-#{term.id}-delete"
  end

  def row_for!(term)
    page.find_by_id(row_id(term))
  end

  def row_selector_for(term)
    "tr##{row_id(term)}"
  end

  def row_for(term)
    row_for!(term) if page.has_selector?(row_selector_for(term))
  end

  def expect_no_row(term)
    expect(page).not_to have_selector(row_selector_for(term))
  end

  def expect_name_field(term)
    term_row = row_for!(term)
    expect(term_row).to have_field(name_field_id(term), type: 'text', with: term.name)
  end

  def expect_no_name_field(term)
    return unless (term_row = row_for(term))

    expect(term_row).not_to have_field(name_field_id(term), type: 'text', with: term.name)
  end

  def expect_updated_at(term)
    term_row = row_for!(term)
    expect(term_row).to have_content(updated_at_str(term))
  end

  def expect_no_updated_at(term)
    return unless (term_row = row_for(term))

    expect(term_row).not_to have_content(updated_at_str(term))
  end

  context 'with lending admin credentials' do
    before { mock_login(:lending_admin) }

    after { logout! }

    describe :index do
      before do
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
          deselected_terms.each { |t| expect_no_row(t) }
        end

        terms_by_time.keys.reverse_each do |time|
          page.uncheck("termFilter-#{time}")
          checked.delete(time)

          expected_terms = checked.empty? ? Term.all : checked.map { |t| terms_by_time[t] }
          deselected_terms = Term.where.not(id: expected_terms.map(&:id))

          expected_terms.each { |t| expect_name_field(t) }
          deselected_terms.each { |t| expect_no_row(t) }
        end
      end

      describe 'editing' do

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

        it 'allows setting a term as default' do
          term1, term2 = Term.limit(2).to_a

          term1_checkbox_id = default_checkbox_id(term1)
          term2_checkbox_id = default_checkbox_id(term2)

          expect(page.find_by_id(term1_checkbox_id)).not_to be_checked # just to be sure
          expect(page.find_by_id(term2_checkbox_id)).not_to be_checked # just to be sure

          page.check(term1_checkbox_id)
          expect_no_updated_at(term1) # wait for updated_at to change

          expect(page.find_by_id(term1_checkbox_id)).to be_checked
          expect(page.find_by_id(term2_checkbox_id)).not_to be_checked

          term1.reload
          expect(term1).to be_default
          expect(Settings.default_term).to eq(term1)

          page.check(term2_checkbox_id)
          expect_no_updated_at(term2) # wait for updated_at to change

          expect(page.find_by_id(term1_checkbox_id)).not_to be_checked
          expect(page.find_by_id(term2_checkbox_id)).to be_checked

          term2.reload
          expect(term2).to be_default
          expect(Settings.default_term).to eq(term2)
        end

        it 'allows editing a term start date' do
          term = Term.take

          start_date = term.start_date - 1.weeks
          start_date_str = start_date.strftime('%m/%d/%Y')
          start_date_field = page.find_field(start_date_field_id(term), type: 'date')
          start_date_field.fill_in(with: start_date_str)

          page.find('body').click # trigger blur event
          expect_no_updated_at(term) # wait for updated_at to change

          term.reload
          expect(term.start_date).to eq(start_date)
          expect_updated_at(term)
        end

        it 'allows editing a term end date' do
          term = Term.take

          end_date = term.end_date + 1.weeks
          end_date_str = end_date.strftime('%m/%d/%Y')
          end_date_field = page.find_field(end_date_field_id(term), type: 'date')
          end_date_field.fill_in(with: end_date_str)

          page.find('body').click # trigger blur event
          expect_no_updated_at(term) # wait for updated_at to change

          term.reload
          expect(term.end_date).to eq(end_date)
          expect_updated_at(term)
        end

        it 'rejects an invalid start date' do
          term = Term.take
          start_date_orig = term.start_date
          updated_at_orig = term.updated_at

          start_date = term.end_date + 1.weeks
          start_date_str = start_date.strftime('%m/%d/%Y')
          start_date_field = page.find_field(start_date_field_id(term), type: 'date')
          start_date_field.fill_in(with: start_date_str)

          page.find('body').click # trigger blur event

          expect_updated_at(term)

          term.reload
          expect(term.start_date).to eq(start_date_orig)
          expect(term.updated_at).to eq(updated_at_orig)

          expect_alert('error', 'start date must precede end date')
        end

        it 'rejects an invalid end date' do
          term = Term.take
          end_date_orig = term.end_date
          updated_at_orig = term.updated_at

          end_date = term.start_date - 1.weeks
          end_date_str = end_date.strftime('%m/%d/%Y')
          end_date_field = page.find_field(end_date_field_id(term), type: 'date')
          end_date_field.fill_in(with: end_date_str)

          page.find('body').click # trigger blur event

          expect_alert('error', 'start date must precede end date')
          expect_updated_at(term)

          term.reload
          expect(term.end_date).to eq(end_date_orig)
          expect(term.updated_at).to eq(updated_at_orig)
        end

      end

      describe 'delete' do
        attr_reader :term

        before do
          @term = Term.take
        end

        it 'deletes a term' do
          expect(term.items).to be_empty # just to be sure

          button = page.find_button(delete_button_id(term))
          button.click

          expect_no_name_field(term)
          expect(Term.exists?(term.id)).to eq(false)

          expect_alert('success', 'Term deleted.')
        end

        describe 'with items' do
          attr_reader :item

          before do
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

      describe 'add' do
        it 'is enabled by default' do
          expect(page).to have_button('Add a term', disabled: false)
        end

        it 'is disabled after being clicked' do
          page.click_button('add-term')
          expect(page).to have_button('Add a term', disabled: true)
        end

        describe 'widget' do
          it 'is not displayed by default' do
            expect(page).not_to have_content('#add-term-widget')
          end

          describe 'adding' do
            let(:new_name) { 'New test term' }
            let(:start_date) { Date.current + 1.weeks }
            let(:start_date_str) { start_date.strftime('%m/%d/%Y') }
            let(:end_date) { start_date + 2.weeks }
            let(:end_date_str) { end_date.strftime('%m/%d/%Y') }

            it 'allows adding a term' do
              page.click_button('add-term')
              widget = page.find('#add-term-widget')
              expect(widget).to have_button('Save', disabled: true)

              name_field = widget.find_field('new-term-name', type: 'text')
              name_field.fill_in(with: new_name, fill_options: { clear: :backspace })
              expect(widget).to have_button('Save', disabled: true)

              start_date_field = widget.find_field('new-term-start-date', type: 'date')
              start_date_field.fill_in(with: start_date_str)
              expect(widget).to have_button('Save', disabled: true)

              end_date_field = widget.find_field('new-term-end-date', type: 'date')
              end_date_field.fill_in(with: end_date_str)
              expect(widget).to have_button('Save', disabled: false)

              save_button = widget.find_button('Save', disabled: false)

              expect do
                save_button.click
                expect_alert('success', 'Term added.')
              end.to change(Term, :count).by(1)

              expect(page).not_to have_content('#add-term-widget')

              new_term = Term.find_by(name: new_name)
              expect(new_term.start_date).to eq(start_date)
              expect(new_term.end_date).to eq(end_date)
            end

            it 'allows setting a default term' do
              old_default_term = (Settings.default_term = Term.take)

              page.click_button('add-term')
              widget = page.find('#add-term-widget')

              widget.check('new-term-default_term')

              name_field = widget.find_field('new-term-name', type: 'text')
              name_field.fill_in(with: new_name, fill_options: { clear: :backspace })

              start_date_field = widget.find_field('new-term-start-date', type: 'date')
              start_date_field.fill_in(with: start_date_str)

              end_date_field = widget.find_field('new-term-end-date', type: 'date')
              end_date_field.fill_in(with: end_date_str)

              save_button = widget.find_button('Save', disabled: false)

              expect do
                save_button.click
                expect_alert('success', 'Term added.')
              end.to change(Term, :count).by(1)

              new_term = Term.find_by(name: new_name)
              expect(Settings.default_term).to eq(new_term)
              expect(new_term).to be_default

              expect(old_default_term).not_to be_default
            end

            it 'prevents adding a term with a duplicate name' do
              page.click_button('add-term')
              widget = page.find('#add-term-widget')

              new_name = Term.take.name
              name_field = widget.find_field('new-term-name', type: 'text')
              name_field.fill_in(with: new_name, fill_options: { clear: :backspace })

              start_date_field = widget.find_field('new-term-start-date', type: 'date')
              start_date_field.fill_in(with: start_date_str)

              end_date = start_date + 2.weeks
              end_date_str = end_date.strftime('%m/%d/%Y')
              end_date_field = widget.find_field('new-term-end-date', type: 'date')
              end_date_field.fill_in(with: end_date_str)

              save_button = widget.find_button('Save', disabled: false)

              expect do
                save_button.click
                expect_alert('error', 'already exists')
              end.not_to change(Term, :count)
            end

            it 'prevents adding a term with a bad date range' do
              page.click_button('add-term')
              widget = page.find('#add-term-widget')

              name_field = widget.find_field('new-term-name', type: 'text')
              name_field.fill_in(with: new_name, fill_options: { clear: :backspace })

              start_date_field = widget.find_field('new-term-start-date', type: 'date')
              start_date_field.fill_in(with: start_date_str)

              end_date = start_date - 3.weeks
              end_date_str = end_date.strftime('%m/%d/%Y')
              end_date_field = widget.find_field('new-term-end-date', type: 'date')
              end_date_field.fill_in(with: end_date_str)
              expect(widget).to have_button('Save', disabled: false)

              save_button = widget.find_button('Save', disabled: false)

              expect do
                save_button.click
                expect_alert('error', 'start date must precede end date')
              end.not_to change(Term, :count)
            end

          end
        end

      end
    end
  end
end
