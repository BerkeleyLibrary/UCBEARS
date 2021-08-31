require 'capybara_helper'

describe LendingController, type: :system do

  # ------------------------------------------------------------
  # Fixture

  let(:factory_names) do
    %i[
      inactive_item
      active_item
      incomplete_no_directory
      incomplete_no_images
      incomplete_no_marc
      incomplete_no_manifest
      incomplete_marc_only
    ]
  end

  let(:states) { %i[active inactive incomplete] }

  attr_reader :items
  attr_reader :item

  def complete
    items.values.select(&:complete?)
  end

  def incomplete
    items.values.reject(&:complete?)
  end

  def active
    # TODO: separate "activated" flag from "active" (= activated AND complete) determination
    complete.select(&:active?)
  end

  def inactive
    complete.reject(&:active?)
  end

  def available
    items.values.select(&:available?)
  end

  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://ucbears-iiif/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

  after(:each) do
    clear_login_state!
  end

  # ------------------------------------------------------------
  # Helper methods

  def expect_no_alerts
    expect(page).not_to have_xpath("//div[contains(@class, 'alerts')]")
  end

  # ------------------------------------------------------------
  # Tests

  context 'as lending admin' do

    describe :login do
      it 'redirects to the index' do
        mock_login(:lending_admin)
        expect(page.title).to include('UC BEARS')
        expect_no_alerts
      end
    end

    context 'with items' do
      before(:each) do
        expect(LendingItem.count).to eq(0) # just to be sure
        # NOTE: we're deliberately not validating here, because we want some invalid items
        @items = factory_names.each_with_object({}) do |fn, items|
          items[fn] = build(fn).tap { |it| it.save!(validate: false) }
        end
        @item = active.first

        mock_login(:lending_admin)
      end

      describe :index do
        before(:each) do
          visit index_path
        end

        def find_item_section(item)
          find(:xpath, "//section[@id='#{LendingHelper.format_html_id(item.directory)}']")
        end

        it 'lists the items' do
          expect(page.title).to include('UC BEARS')
          expect_no_alerts

          aggregate_failures :items do
            items.each_value do |item|
              expect(page).to have_content(item.title)
            end
          end
        end

        it 'categorizes the items by state' do
          sections_by_state = states.map do |state|
            [state, find(:xpath, "//section[@id='lending-#{state}']")]
          end.to_h

          states.each do |state|
            items_for_state = send(state)
            expect(items_for_state).not_to be_empty, "No items for state #{state}" # just to be sure

            section = sections_by_state[state]
            item_sections = section.all(:xpath, ".//section[@class='lending-item']")
            row_count = item_sections.size
            item_count = items_for_state.size
            expect(row_count).to eq(item_count), "Expected #{item_count} rows for #{state}, got #{row_count}: #{item_sections.map(&:text).join(', ')}"

            items_for_state.each do |item|
              item_section = section.find(:xpath, ".//section[@class='lending-item' and h3[contains(text(), '#{item.title}')]]")
              show_path = lending_show_path(directory: item.directory)
              expect(item_section).to have_link('Show', href: /#{Regexp.escape(show_path)}/)
            end
          end
        end

        it 'has show and edit buttons for all items' do
          items.each_value do |item|
            item_section = find_item_section(item)
            show_path = lending_show_path(directory: item.directory)
            show_link = item_section.find_link('Show')
            expect(URI.parse(show_link['href']).path).to eq(show_path)

            edit_path = lending_edit_path(directory: item.directory)
            edit_link = item_section.find_link('Edit item')
            expect(URI.parse(edit_link['href']).path).to eq(edit_path)
          end
        end

        it 'has "make active" only for processed, inactive items with copies' do
          items.each_value do |item|
            item_section = find_item_section(item)
            expect(item_section).to have_content(item.title)

            activate_path = lending_activate_path(directory: item.directory)

            if item.active? || item.incomplete?
              expect(item_section).not_to have_link('Make Active'), "Item #{item.directory} (#{item.status}) should not have 'Make Active' link"
            else
              activate_link = item_section.find_link('Make Active')
              expect(URI.parse(activate_link['href']).path).to eq(activate_path)
            end
          end
        end

        it 'has "make inactive" only for processed, active items' do
          items.each_value do |item|
            item_section = find_item_section(item)
            deactivate_path = lending_deactivate_path(directory: item.directory)
            if item.incomplete? || !item.active?
              expect(item_section).not_to have_link('Make Inactive'), "Item #{item.directory} should not have 'Make Inactive' link"
            else
              link = item_section.find_link('Make Inactive')
              expect(URI.parse(link['href']).path).to eq(deactivate_path)
            end
          end
        end

        it 'has "delete" only for incomplete items' do
          items.each_value do |item|
            item_section = find_item_section(item)
            delete_path = lending_destroy_path(directory: item.directory)
            if item.incomplete?
              delete_form = item_section.find(:xpath, ".//form[@action='#{delete_path}']")
              expect(delete_form).to have_button('Delete')
            else
              expect(item_section).not_to have_xpath(".//form[@action='#{delete_path}']")
              expect(item_section).not_to have_button('Delete'), "Item #{item.directory} should not have 'Delete' button"
            end
          end
        end

        describe 'Show' do
          it 'shows the item preview' do
            item = active.first
            item_section = find_item_section(item)

            show_path = lending_show_path(directory: item.directory)
            show_link = item_section.find_link('Show')
            expect(URI.parse(show_link['href']).path).to eq(show_path)
            show_link.click

            expect_no_alerts
            expect(page).to have_current_path(show_path)
          end
        end

        describe 'Edit item' do
          it 'shows the edit screen' do
            item = active.find { |it| it.copies > 0 }
            item_section = find_item_section(item)

            edit_path = lending_edit_path(directory: item.directory)
            edit_link = item_section.find_link('Edit item')
            expect(URI.parse(edit_link['href']).path).to eq(edit_path)
            edit_link.click

            expect_no_alerts
            expect(page).to have_current_path(edit_path)
          end
        end

        describe 'Make Active' do
          before(:each) do
            inactive.first.update(copies: 2)
            visit index_path
          end

          it 'activates an item' do
            item = inactive.find { |it| it.copies > 0 }
            item_section = find_item_section(item)

            activate_path = lending_activate_path(directory: item.directory)
            activate_link = item_section.find_link('Make Active')
            expect(URI.parse(activate_link['href']).path).to eq(activate_path)
            activate_link.click

            active_section = find(:xpath, "//section[@id='lending-active']")
            expect(active_section).to have_xpath(".//section[@class='lending-item' and h3[contains(text(), '#{item.title}')]]")

            alert = page.find('.alert-success')
            expect(alert).to have_text('Item now active.')

            item.reload
            expect(item).to be_active
          end
        end

        describe 'Delete' do
          it 'deletes an inactive item' do
            item = incomplete.first
            item_section = find_item_section(item)

            delete_path = lending_destroy_path(directory: item.directory)
            delete_form = item_section.find(:xpath, ".//form[@action='#{delete_path}']")
            delete_button = delete_form.find_button('Delete')

            delete_button.click

            alert = page.find('.alert-success')
            expect(alert).to have_text('Item deleted.')

            expect(page).not_to have_content(item.title)

            expect(LendingItem.exists?(item.id)).to eq(false)
          end
        end

        it 'does not delete a complete item' do
          item = LendingItem.find_by(directory: 'b23752729_C118406204')
          expect(item).not_to be_complete # just to be sure

          item_section = find_item_section(item)

          delete_button_xpath = ".//form[@action='#{lending_destroy_path(directory: item.directory)}']"
          delete_form = item_section.find(:xpath, delete_button_xpath)
          delete_button = delete_form.find_button('Delete')

          mf = Lending::IIIFManifest.new(title: item.title, author: item.author, dir_path: item.iiif_dir)
          begin
            mf.write_manifest_erb!
            expect(item).to be_complete # just to be sure

            delete_button.click
            alert = page.find('.alert-danger')
            expect(alert).to have_text('Only incomplete items can be deleted.')

            expect(page).to have_content(item.title)
            expect(page).not_to have_content(delete_button_xpath)

            expect(LendingItem.exists?(item.id)).to eq(true)
          ensure
            FileUtils.rm(mf.erb_path)
          end
        end
      end

      describe :stats do
        it 'displays the stats' do
          visit lending_stats_path
          expect(page.title).to include('Statistics')
        end
      end

      describe :show do
        it 'displays all due dates' do
          item = active.find { |it| it.copies > 1 }
          loans = item.copies.times.with_object([]) do |i, ll|
            loan = item.check_out_to!("patron-#{i}")
            loan.due_date = loan.due_date + i.days # just to differentiate
            loan.save!
            ll << loan
          end

          visit lending_show_path(directory: item.directory)

          loans.each do |loan|
            expect(page).to have_content(loan.due_date.to_s(:short))
          end
        end

        # TODO: Test MARC reload
      end

      describe :edit do
        it 'allows the item to be edited' do
          visit lending_edit_path(directory: item.directory)

          new_values = {
            title: 'The Great Depression in Europe, 1929-1939',
            author: 'Patricia Clavin',
            publisher: 'New York: St. Martin’s Press, 2000',
            physical_desc: 'viii, 244 p.; ill.; 23 cm.',
            copies: 12
          }
          new_values.each do |attr, value|
            field_id = "lending_item_#{attr}"
            field = page.find_field(field_id)
            field.fill_in(with: value, fill_options: { clear: :backspace })

            page.find_field(field_id)
            expect(field.value).to eq(value.to_s)
          end

          expect(item).to be_active # just to be sure

          page.choose('lending_item_active_0')

          submit_button = find(:xpath, "//input[@type='submit']")
          submit_button.click

          expect(page).to have_content('Item updated.')

          old_values = new_values.each_key.with_object({}) { |attr, vv| vv[attr] = item.send(attr) }
          old_values.each do |attr, value|
            next if attr == :copies # too easy for numbers to appear in Mirador

            expect(page).not_to have_content(value), "Old value for #{attr} found: #{value.inspect}"
          end

          item.reload
          expect(item).not_to be_active
          new_values.each do |attr, value|
            expect(item.send(attr)).to eq(value)
          end

          metadata_table = page.find('table.item-metadata')
          new_values.each_value do |value|
            expect(metadata_table).to have_content(value)
          end
        end
      end
    end
  end

  context 'as patron' do
    attr_reader :user
    attr_reader :item

    before(:each) do
      @user = mock_login(:student)
      expect(LendingItem.count).to eq(0) # just to be sure
      # NOTE: we're deliberately not validating here, because we want some invalid items
      @items = factory_names.each_with_object({}) do |fn, items|
        items[fn] = build(fn).tap { |it| it.save!(validate: false) }
      end
    end

    after(:each) { logout! }

    context 'with available item' do
      before(:each) do
        @item = active.find(&:available?)
      end

      describe :view do
        it 'allows a checkout' do
          expect(item).to be_available # just to be sure
          expect(LendingItemLoan.where(patron_identifier: user.borrower_id)).not_to exist # just to be sure

          visit lending_view_path(directory: item.directory)
          expect(page).not_to have_selector('div#iiif_viewer')

          checkout_path = lending_check_out_path(directory: item.directory)
          checkout_link = page.find_link('Check out')
          expect(URI.parse(checkout_link['href']).path).to eq(checkout_path)
          checkout_link.click

          alert = page.find('.alert-success')
          expect(alert).to have_text('Checkout successful.')

          expect(page).to have_selector('div#iiif_viewer')
        end

        it 'allows a return' do
          item.check_out_to(user.borrower_id)

          visit lending_view_path(directory: item.directory)

          return_path = lending_return_path(directory: item.directory)
          return_link = page.find_link('Return now')
          expect(URI.parse(return_link['href']).path).to eq(return_path)
          return_link.click

          alert = page.find('.alert-success')
          expect(alert).to have_text('Item returned.')

          expect(page).not_to have_selector('div#iiif_viewer')
        end

        it 'requires a token' do
          original_user = user
          item.check_out_to(original_user.borrower_id)

          logout!
          user = mock_login(:student)
          expect(user.uid).to eq(original_user.uid) # just to be sure
          expect(user.borrower_id).not_to eq(original_user.borrower_id) # just to be sure

          visit lending_view_path(directory: item.directory)
          expect(page).not_to have_selector('div#iiif_viewer')
        end

        it 'accepts a token in the URL' do
          original_user = user
          item.check_out_to(original_user.borrower_id)

          logout!
          user = mock_login(:student)
          expect(user.uid).to eq(original_user.uid) # just to be sure
          expect(user.borrower_id).not_to eq(original_user.borrower_id) # just to be sure

          visit lending_view_path(directory: item.directory, token: original_user.borrower_token.token_str)
          expect(page).to have_selector('div#iiif_viewer')
        end

        it 'updates the user token from the URL' do
          original_user = user
          item.check_out_to(original_user.borrower_id)

          logout!
          user = mock_login(:student)
          expect(user.uid).to eq(original_user.uid) # just to be sure
          expect(user.borrower_id).not_to eq(original_user.borrower_id) # just to be sure

          visit lending_view_path(directory: item.directory, token: original_user.borrower_token.token_str)
          expect(page).to have_selector('div#iiif_viewer')
        end

        it 'redirects to a URL with a token' do
          item.check_out_to(user.borrower_id)

          expected_path = lending_view_path(directory: item.directory, token: user.borrower_token.token_str)

          visit lending_view_path(directory: item.directory)
          expect(page).to have_selector('div#iiif_viewer')
          expect(page.current_url).to include(expected_path)
        end

        it 'displays a warning when loan has expired' do
          loan_date = Time.current.utc - 3.weeks
          due_date = loan_date + LendingItem::LOAN_DURATION_SECONDS.seconds
          loan = LendingItemLoan.create(
            lending_item_id: item.id,
            patron_identifier: user.borrower_id,
            loan_status: :active,
            loan_date: loan_date,
            due_date: due_date
          )
          loan.reload

          visit lending_view_path(directory: item.directory)

          alert = page.find('.alert-danger')
          expect(alert).to have_text('Your loan term has expired.')

          expect(page).not_to have_selector('div#iiif_viewer')
        end

        it 'redirects when loan expires' do
          loan = item.check_out_to(user.borrower_id)

          # Capybara doesn't seem to respect the meta-refresh, so we'll just
          # make sure it's there
          visit lending_view_path(directory: item.directory)
          meta_refresh = page.find(:xpath, '/html/head/meta[@http-equiv="Refresh"]', visible: false)

          md = /([0-9]+); URL=(.*)/.match(meta_refresh[:content])
          redirect_uri = URI.parse(md[2])
          expect(redirect_uri.path).to eq(lending_return_path(directory: item.directory))

          redirect_after = md[1].to_i
          expect(redirect_after).to be_within(60).of(loan.seconds_remaining)
        end
      end
    end

    context 'with inactive item' do
      before(:each) do
        @item = inactive.first
      end

      describe :view do
        it "doesn't allow a checkout" do
          expect(item).not_to be_available # just to be sure
          expect(LendingItemLoan.where(patron_identifier: user.borrower_id)).not_to exist # just to be sure

          visit lending_view_path(directory: item.directory)
          expect(page).not_to have_selector('div#iiif_viewer')

          expect(page).not_to have_link('Check out')
        end

        it "doesn't leave spurious warnings on other pages" do
          visit lending_view_path(directory: item.directory)

          alert = page.find('.alert-danger')
          expect(alert).to have_text('This item is not in active circulation.')

          available_item = available.first
          visit lending_view_path(directory: available_item.directory)

          expect(page).to have_link('Check out')
          expect(page).not_to have_selector('.alert-danger')
        end
      end
    end
  end
end
