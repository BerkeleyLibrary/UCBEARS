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

  attr_reader :current_term

  before do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end

    @prev_default_term = Settings.default_term
    @current_term = create(:term, name: 'Test 1', start_date: Date.current - 1.days, end_date: Date.current + 1.days)
    Settings.default_term = current_term
  end

  after do
    logout!
    Settings.default_term = @prev_default_term
  end

  # ------------------------------------------------------------
  # Helper methods

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

  def expect_no_alert(lvl, msg)
    alert = find_alert(lvl)
    expect(alert).not_to have_text(msg)
  rescue Capybara::ElementNotFound
    # expected
  end

  def expect_no_alerts(lvl = nil)
    alerts = page.find(:xpath, '//aside[@id="flash"]')
    return unless alerts && lvl

    expect(alerts).not_to have_xpath("//div[@class=\"#{lvl}\"]")
  rescue Capybara::ElementNotFound
    # expected
  end

  def expect_link_or_button(element, text, href)
    link_or_button = element.find(:link_or_button, text)
    expect_target(link_or_button, href)
  end

  def expect_target(link_or_button, target)
    tag_name = link_or_button.tag_name
    if %w[input button].include?(tag_name)
      form = link_or_button.find(:xpath, './ancestor::form')
      expect(form['action']).to match(target)
    else
      expect(link_or_button['href']).to match(target)
    end
  end

  # ------------------------------------------------------------
  # Tests

  context 'as lending admin' do

    context 'with items' do
      before do
        expect(Item.count).to eq(0) # just to be sure
        # NOTE: we're deliberately not validating here, because we want some invalid items
        @items = factory_names.each_with_object({}) do |fn, items|
          items[fn] = build(fn).tap { |it| it.save!(validate: false) }
        end
        @item = active.first

        mock_login(:lending_admin)
      end

      describe :stats do
        it 'displays the stats' do
          visit stats_path
          expect(page.title).to include('Statistics')
        end
      end

      describe :show do

        attr_reader :alma_items

        before do
          @alma_items = []

          Item.find_each do |it|
            sru_data_path = sru_data_path_for(it.record_id)
            next unless File.exist?(sru_data_path)

            stub_sru_request(it.record_id)
            alma_items << it
          end
        end

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
            expect(page).to have_content(loan.due_date.to_fs(:short))
          end
        end

        it 'displays the MMS ID and permalink where available' do
          alma_items.each do |item|
            expect(item.alma_mms_id).not_to be_nil # just to be sure

            visit lending_show_path(directory: item.directory)
            expect(page).to have_content(item.alma_mms_id.to_s)
            expect(page).to have_link(href: item.alma_permalink.to_s)
          end
        end

        xit 'only shows the viewer for complete items'
        xit 'shows a message for incomplete items'
      end

      describe :edit do
        # rubocop:disable RSpec/ExampleLength
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

          page.click_link_or_button('Save Changes')

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
        # rubocop:enable RSpec/ExampleLength

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

          page.accept_alert 'Reloading MARC metadata will discard all changes made on this form.' do
            page.click_link_or_button('Reload MARC metadata')
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

    before do
      @user = mock_login(:student)
      expect(Item.count).to eq(0) # just to be sure
      # NOTE: we're deliberately not validating here, because we want some invalid items
      @items = factory_names.each_with_object({}) do |fn, items|
        items[fn] = build(fn).tap { |it| it.save!(validate: false) }
      end
    end

    after { logout! }

    context 'with available item' do
      before do
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
            item.update(copies: 1)
            expect(item).to be_available # just to be sure
            expect(Loan.where(patron_identifier: user.borrower_id)).not_to exist # just to be sure

            visit lending_view_path(directory: item.directory)
            expect(page).not_to have_selector('div#iiif_viewer')

            page.click_link_or_button('Check out')
            expect_alert(:success, 'Checkout successful.')
            expect_no_alerts(:danger)

            expect(page).to have_selector('div#iiif_viewer')
            expect(item).not_to be_available # just to be sure
          end

          it 'disallows checkouts if the patron has hit the limit' do
            other_item = inactive.first
            other_item.update(active: true, copies: 1)
            other_item.check_out_to(user.borrower_id)

            visit lending_view_path(directory: item.directory)
            expect_alert(:danger, Item::MSG_CHECKOUT_LIMIT_REACHED)

            expect(page).not_to have_selector(:link_or_button, 'Check out')
          end

          it 'displays an error on a double checkout, but displays the item' do
            visit lending_view_path(directory: item.directory)

            item.check_out_to(user.borrower_id)
            count_before = Loan.where(patron_identifier: user.borrower_id).count

            page.click_link_or_button('Check out')

            expect_alert(:danger, Item::MSG_CHECKED_OUT)
            expect_no_alerts(:success)

            expect(page).to have_selector('div#iiif_viewer')
            expect_link_or_button(page, 'Return now', lending_return_path(directory: item.directory))

            count_after = Loan.where(patron_identifier: user.borrower_id).count
            expect(count_after).to eq(count_before)
          end
        end

        describe 'returns' do

          it 'allows a return' do
            item.check_out_to(user.borrower_id)

            visit lending_view_path(directory: item.directory)
            page.click_link_or_button('Return now')

            expect_alert(:success, 'Item returned.')
            expect_no_alerts(:danger)

            expect(page).not_to have_selector('div#iiif_viewer')
          end

          it 'does not show spurious errors messages after returning an expired item' do
            item.check_out_to(user.borrower_id)

            visit lending_view_path(directory: item.directory)

            loan = item.loans.active.find_by(patron_identifier: user.borrower_id)
            expect(loan).not_to be_nil # just to be sure
            loan.update!(loan_date: loan.loan_date - 1.days, due_date: loan.due_date - 1.days)

            page.click_link_or_button('Return now')

            expect_alert(:success, 'Item returned.')
            expect_no_alerts(:danger)
          end

          it 'allows a return of an item that has become inactive' do
            item.check_out_to(user.borrower_id)

            visit lending_view_path(directory: item.directory)
            item.update(active: false)

            page.click_link_or_button('Return now')

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

        # TODO: figure out what we really intended here
        xit 'updates the user token from the URL' do
          original_user = user
          item.check_out_to(original_user.borrower_id)

          logout!
          user = mock_login(:student)
          expect(user.uid).to eq(original_user.uid) # just to be sure
          expect(user.borrower_id).not_to eq(original_user.borrower_id) # just to be sure

          visit lending_view_path(directory: item.directory, token: original_user.borrower_token.token_str)
          expect(user.borrower_token).to eq(original_user.borrower_token)
          expect(user.borrower_id).to eq(original_user.borrower_id)
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
          loan = Loan.create(
            item_id: item.id,
            patron_identifier: user.borrower_id,
            loan_date:,
            due_date:
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
      before do
        @item = inactive.first
      end

      describe :view do
        it "doesn't allow a checkout" do
          expect(item).not_to be_available # just to be sure
          expect(Loan.where(patron_identifier: user.borrower_id)).not_to exist # just to be sure

          visit lending_view_path(directory: item.directory)
          expect(page).not_to have_selector('div#iiif_viewer')

          expect(page).not_to have_selector(:link_or_button, 'Check out')
        end

        it "doesn't leave spurious warnings on other pages" do
          visit lending_view_path(directory: item.directory)

          expect_alert(:danger, 'This item is not in active circulation.')

          available_item = available.first
          visit lending_view_path(directory: available_item.directory)

          expect(page).to have_selector(:link_or_button, 'Check out')
          expect_no_alerts
        end
      end
    end
  end
end
