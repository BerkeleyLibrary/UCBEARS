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
      iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

  after(:each) do
    logout!
  end

  # ------------------------------------------------------------
  # Helper methods

  def find_alerts
    page.find('aside#flash')
  end

  def find_alert(lvl)
    alerts = find_alerts
    alerts.find("li.#{lvl}")
  end

  # TODO: make this work with multiple alerts at same level
  def expect_alert(lvl, msg)
    alert = find_alert(lvl)
    expect(alert).to have_text(msg)
  end

  def expect_no_alert(lvl, msg)
    alert = find_alert(lvl)
    expect(alert).not_to have_text(msg)
  rescue Capybara::ElementNotFound
    # expected
  end

  def expect_no_alerts(lvl = nil)
    alerts = page.find(:xpath, '//aside[@id="flash"]')
    return unless alerts && lvl

    expect(alerts).not_to have_xpath("//li[@class=\"#{lvl}\"]")
  rescue Capybara::ElementNotFound
    # expected
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
        expect(Item.count).to eq(0) # just to be sure
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
          xpath = item_section_xpath(item)
          find(:xpath, xpath)
        end

        def item_section_xpath(item, absolute: true)
          id = LendingHelper.format_html_id(item.directory)
          path = "//section[@id='#{id}']"
          absolute ? path : ".#{path}"
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
              item_section = section.find(:xpath, item_section_xpath(item, absolute: false))
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
            expect(active_section).to have_xpath(item_section_xpath(item, absolute: false))

            expect_alert(:success, 'Item now active.')
            expect_no_alerts(:danger)

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

            expect_alert(:success, 'Item deleted.')
            expect_no_alerts(:danger)

            expect(page).not_to have_content(item.title)

            expect(Item.exists?(item.id)).to eq(false)
          end

          it 'works for incomplete items that differ from complete items only by "file extension"' do
            attributes = attributes_for(:complete_item).tap do |attrs|
              attrs[:directory] = "#{attrs[:directory]}.orig"
            end
            item = Item.create!(attributes)
            expect(item.directory).to end_with('.orig') # just to be sure

            visit index_path

            item_section = find_item_section(item)

            delete_path = lending_destroy_path(directory: item.directory)
            expect(delete_path).to end_with(item.directory) # just to be sure

            delete_path = lending_destroy_path(directory: item.directory)
            delete_form = item_section.find(:xpath, ".//form[@action='#{delete_path}']")
            delete_button = delete_form.find_button('Delete')

            delete_button.click

            expect_alert(:success, 'Item deleted.')
            expect_no_alerts(:danger)

            expect(page).not_to have_content(item.directory)
            expect(Item.exists?(item.id)).to eq(false)
          end
        end

        it 'does not delete a complete item' do
          item = Item.find_by(directory: 'b23752729_C118406204')
          expect(item).not_to be_complete # just to be sure

          item_section = find_item_section(item)

          delete_button_xpath = ".//form[@action='#{lending_destroy_path(directory: item.directory)}']"
          delete_form = item_section.find(:xpath, delete_button_xpath)
          delete_button = delete_form.find_button('Delete')

          mf = Lending::IIIFManifest.new(title: item.title, author: item.author, dir_path: item.iiif_dir)
          begin
            mf.write_manifest_erb!
            item.reload

            # just to be sure
            expect(item).to be_complete, -> { "Item #{item.directory} should be complete, but: #{item.reason_incomplete}" }

            delete_button.click
            expect_alert(:danger, 'Only incomplete items can be deleted.')

            expect(page).to have_content(item.title)
            expect(page).not_to have_content(delete_button_xpath)

            expect(Item.exists?(item.id)).to eq(true)
          ensure
            FileUtils.rm(mf.erb_path)
          end
        end

        describe 'processing' do
          it 'displays the list of in-process directories' do
            final_actual = Lending.stage_root_path(:final).realpath

            Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |tmp|
              lending_root = Pathname.new(tmp)
              FileUtils.ln_s(final_actual, lending_root.join('final')) # make unrelated code work

              processing_tmp = lending_root.join('processing')
              processing_tmp.mkdir

              processing_time_limit = Rails.application.config.processing_time_limit

              dirnames = ['b18357550_C106160623', 'b23752729_C118406204', 'b135297126_BT 7 064 812']
              processing_dirs = dirnames.map.with_index do |dirname, i|
                processing_tmp.join(dirname).tap do |dirpath|
                  dirpath.mkdir
                  new_mtime = (Time.current - (2 * i * processing_time_limit / 3)).to_time
                  FileUtils.touch(dirpath, mtime: new_mtime)
                end
              end

              allow(Lending::Config).to receive(:lending_root_path).and_return(lending_root)

              visit index_path
              processing_section = find(:xpath, '//section[@id="lending-processing"]')
              rows = processing_section.find('tbody').find_all('tr')
              processing_dirs.each do |dirpath|
                row = rows.find { |r| r.has_selector?('td', text: dirpath.basename.to_s) }
                expect(row).not_to be_nil

                stale = (Time.current - dirpath.mtime) > processing_time_limit
                expect(row).to have_selector('td.problems', text: '⚠️') if stale
              end
            end
          end
        end
      end

      describe :stats do
        it 'displays the stats' do
          visit stats_path
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

        xit 'only shows the viewer for complete items'
        xit 'shows a message for incomplete items'
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
            field_id = "item_#{attr}"
            field = page.find_field(field_id)
            field.fill_in(with: value, fill_options: { clear: :backspace })

            page.find_field(field_id)
            expect(field.value).to eq(value.to_s)
          end

          expect(item).to be_active # just to be sure

          page.choose('item_active_0')

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

        it 'allows reloading MARC metadata' do
          new_values = {
            title: 'The Great Depression in Europe, 1929-1939',
            author: 'Patricia Clavin',
            publisher: 'New York: St. Martin’s Press, 2000',
            physical_desc: 'viii, 244 p.; ill.; 23 cm.'
          }
          original_values = new_values.each_key.with_object({}) { |attr, vv| vv[attr] = item.send(attr) }

          item.update!(new_values)

          visit lending_edit_path(directory: item.directory)

          reload_link = page.find_link('Reload MARC metadata')

          page.accept_alert 'Reloading MARC metadata will discard all changes made on this form.' do
            reload_link.click
          end

          expect(page).to have_content('MARC metadata reloaded.')

          item.reload

          original_values.each do |attr, value|
            expect(item.send(attr)).to eq(value)
          end

          metadata_table = page.find('table.item-metadata')
          original_values.each_value do |value|
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
      expect(Item.count).to eq(0) # just to be sure
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
        describe 'skip link' do
          let(:skip_link_text) { 'Skip to main content' }

          it 'is tabbable' do
            path = lending_view_path(directory: item.directory)
            visit path

            page.send_keys(:tab)
            elem = CapybaraHelper.active_element

            expect(elem.tag_name).to eq('a')
            href_uri = URI.parse(elem['href'])
            expect(href_uri.path).to eq(path)
            expect(href_uri.fragment).to eq('main')

            # TODO: get Capybara to actually make it visible and clickable
          end
        end

        describe 'checkouts' do

          it 'allows a checkout' do
            expect(item).to be_available # just to be sure
            expect(LendingItemLoan.where(patron_identifier: user.borrower_id)).not_to exist # just to be sure

            visit lending_view_path(directory: item.directory)
            expect(page).not_to have_selector('div#iiif_viewer')

            checkout_path = lending_check_out_path(directory: item.directory)
            checkout_link = page.find_link('Check out')
            expect(URI.parse(checkout_link['href']).path).to eq(checkout_path)
            checkout_link.click

            expect_alert(:success, 'Checkout successful.')
            expect_no_alerts(:danger)

            expect(page).to have_selector('div#iiif_viewer')
          end

          it 'does not show spurious "unavailable" messages after a checkout' do
            item.update!(copies: 1)

            visit lending_view_path(directory: item.directory)
            checkout_link = page.find_link('Check out')

            checkout_link.click

            expect_alert(:success, 'Checkout successful.')
            expect_no_alerts(:danger)

            expect(item).not_to be_available # just to be sure
            expect_no_alerts('danger')
          end

          it 'disallows checkouts if the patron has hit the limit' do
            other_item = inactive.first
            other_item.update(active: true, copies: 1)
            other_item.check_out_to(user.borrower_id)

            visit lending_view_path(directory: item.directory)
            expect_alert(:danger, Item::MSG_CHECKOUT_LIMIT_REACHED)

            expect(page).not_to have_link('Check out')
          end

          it 'displays an error on a double checkout, but displays the item' do
            visit lending_view_path(directory: item.directory)

            item.check_out_to(user.borrower_id)
            count_before = LendingItemLoan.where(patron_identifier: user.borrower_id).count

            checkout_link = page.find_link('Check out')
            checkout_link.click

            expect_alert(:danger, Item::MSG_CHECKED_OUT)
            expect_no_alerts(:success)

            expect(page).to have_selector('div#iiif_viewer')
            expect(page).to have_link('Return now')

            count_after = LendingItemLoan.where(patron_identifier: user.borrower_id).count
            expect(count_after).to eq(count_before)
          end
        end

        describe 'returns' do

          it 'allows a return' do
            item.check_out_to(user.borrower_id)

            visit lending_view_path(directory: item.directory)

            return_path = lending_return_path(directory: item.directory)
            return_link = page.find_link('Return now')
            expect(URI.parse(return_link['href']).path).to eq(return_path)
            return_link.click

            expect_alert(:success, 'Item returned.')
            expect_no_alerts(:danger)

            expect(page).not_to have_selector('div#iiif_viewer')
          end

          it 'does not show spurious "not checked out" messages after a return' do
            item.check_out_to(user.borrower_id)

            visit lending_view_path(directory: item.directory)
            return_link = page.find_link('Return now')

            return_link.click

            expect_alert(:success, 'Item returned.')
            expect_no_alerts(:danger)

            expect_no_alerts('danger')
          end

          it 'does not show spurious errors messages after returning an expired item' do
            item.check_out_to(user.borrower_id)

            visit lending_view_path(directory: item.directory)
            return_link = page.find_link('Return now')

            loan = item.lending_item_loans.active.find_by(patron_identifier: user.borrower_id)
            expect(loan).not_to be_nil # just to be sure
            loan.update!(loan_date: loan.loan_date - 1.days, due_date: loan.due_date - 1.days)

            return_link.click

            expect_alert(:success, 'Item returned.')
            expect_no_alerts(:danger)
          end

          it 'allows a return of an item that has become inactive' do
            item.check_out_to(user.borrower_id)

            visit lending_view_path(directory: item.directory)
            return_link = page.find_link('Return now')

            item.update(active: false)

            return_link.click

            expect_alert(:success, 'Item returned.')
            expect_alert(:danger, 'This item is not in active circulation.')
            expect_no_alert(:danger, 'This item is not checked out.')
          end
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
          due_date = loan_date + Item::LOAN_DURATION_SECONDS.seconds
          loan = LendingItemLoan.create(
            item_id: item.id,
            patron_identifier: user.borrower_id,
            loan_date: loan_date,
            due_date: due_date
          )
          loan.reload

          visit lending_view_path(directory: item.directory)

          expect_alert(:danger, 'Your loan term has expired.')

          expect(page).not_to have_selector('div#iiif_viewer')
        end

        it 'redirects when loan expires' do
          loan = item.check_out_to(user.borrower_id)

          # Timing the meta-refresh with Capybara is tricky, so we'll just confirm that it's there
          visit lending_view_path(directory: item.directory)
          meta_refresh = page.find(:xpath, '/html/head/meta[@http-equiv="Refresh"]', visible: false)

          md = /([0-9]+); URL=(.*)/.match(meta_refresh[:content])
          redirect_uri = URI.parse(md[2])
          expect(redirect_uri.path).to eq(lending_view_path(directory: item.directory, token: user.borrower_token))

          remaining = loan.seconds_remaining
          redirect_after = md[1].to_i
          expect(redirect_after).to be > remaining
          expect(redirect_after).to be_within(60).of(remaining)
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

          expect_alert(:danger, 'This item is not in active circulation.')

          available_item = available.first
          visit lending_view_path(directory: available_item.directory)

          expect(page).to have_link('Check out')
          expect_no_alerts
        end
      end
    end
  end
end
