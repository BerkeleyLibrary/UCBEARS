require 'rails_helper'

describe LendingController, type: :request do
  let(:factory_names) do
    %i[
      complete_item
      active_item
      incomplete_no_directory
      incomplete_no_images
      incomplete_no_marc
      incomplete_no_manifest
      incomplete_marc_only
    ]
  end

  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://ucbears-iiif/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

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

  after(:each) { logout! }

  context 'with lending admin credentials' do
    before(:each) { mock_login(:lending_admin) }

    context 'without any items' do
      describe :index do
        it 'shows an empty list' do
          get index_path
          expect(response).to be_successful
        end
      end

      describe :stats do
        it 'displays the stats' do
          get lending_stats_path
          expect(response).to be_successful
        end
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
      end

      describe :index do
        it 'lists the items' do
          get index_path
          expect(response).to be_successful

          body = response.body
          items.each_value do |item|
            expect(body).to include(CGI.escapeHTML(item.title))
            expect(body).to include(item.author)
            expect(body).to include(item.directory)
          end
        end

        it 'shows due dates' do
          loans = active.each_with_object([]) do |item, ll|
            item.copies.times do |_copy|
              loan = item.check_out_to!("patron-#{ll.size}")
              ll << loan
            end
          end

          get index_path
          body = response.body
          loans.each do |loan|
            date = loan.due_date
            expect(body).to include(date.to_s(:short))
          end
        end

        it 'auto-expires overdue loans' do
          active.each do |items|
            expect(items.lending_item_loans).to be_empty
          end
          loans = active.each_with_object([]) do |item, ll|
            item.copies.times do |copy|
              loan = item.check_out_to!("patron-#{item.directory}-#{copy}")
              loan.due_date = Time.current.utc - 1.days if copy.odd?
              loan.save!
              ll << loan
            end
          end

          get index_path
          body = response.body

          loans.each do |loan|
            loan.reload
            date = loan.due_date
            if loan.expired?
              expect(loan).to be_complete
              expect(body).not_to include(date.to_s(:short))
            else
              expect(body).to include(date.to_s(:short))
            end
          end
        end
      end

      describe :profile do
        let(:profile_path) { 'public/profile.html' }

        it 'generates a profile' do
          get lending_profile_path
          expect(File.exist?(profile_path)).to eq(true)

          get '/profile.html'
          expect(response).to be_successful
        ensure
          FileUtils.rm_f(profile_path)
        end
      end

      describe :stats do
        it 'displays the stats' do
          get lending_stats_path
          expect(response).to be_successful
        end
      end

      describe :show do
        it 'shows an item' do
          items.each_value do |item|
            get lending_show_path(directory: item.directory)
            expect(response).to be_successful
          end
        end

        it 'returns 404 not found for nonexistent items' do
          get lending_show_path(directory: 'not_a_directory')
          expect(response.status).to eq(404)
        end

        xit 'only shows the viewer for complete items'
        xit 'shows a message for incomplete items'
      end

      describe :edit do
        it 'displays the form' do
          items.each_value do |item|
            get lending_edit_path(directory: item.directory)
            expect(response).to be_successful
            update_path = lending_update_path(directory: item.directory)
            expect(response.body).to include(update_path)
          end
        end

        it 'returns 404 not found for nonexistent items' do
          get lending_edit_path(directory: 'not_a_directory')
          expect(response.status).to eq(404)
        end
      end

      describe :manifest do
        it 'shows the manifest for complete items' do
          complete.each do |item|
            get lending_manifest_path(directory: item.directory)
            expect(response).to be_successful

            # TODO: validate manifest contents
          end
        end

        it 'returns 404 not found for nonexistent items' do
          get lending_manifest_path(directory: 'not_a_directory')
          expect(response.status).to eq(404)
        end
      end

      describe :update do
        it 'updates an item' do
          new_attributes = { copies: 2 }

          complete.each do |item|
            directory = item.directory

            expect do
              patch lending_update_path(directory: directory), params: { lending_item: new_attributes }
            end.not_to change(LendingItem, :count)

            expect(response).to redirect_to lending_show_path(directory: directory)

            item.reload
            new_attributes.each { |attr, val| expect(item.send(attr)).to eq(val) }
          end
        end

        describe 'invalid updates' do
          it 'returns 422 for activating an inactive item' do
            item = incomplete.find { |it| !it.active? }
            expect(item).not_to be_nil # just to be sure

            patch lending_update_path(directory: item.directory), params: { lending_item: { active: true, copies: 17 } }
            expect(response.status).to eq(422)

            item.reload
            expect(item).not_to be_active
            expect(item.copies).not_to eq(17)
          end

          it 'returns 422 for an invalid number of copies' do
            item = inactive.first
            expect(item).not_to be_nil # just to be sure

            patch lending_update_path(directory: item.directory), params: { lending_item: { active: true, copies: -1 } }
            expect(response.status).to eq(422)

            item.reload
            expect(item).not_to be_active
            expect(item.copies).not_to eq(-1)
          end

          it 'returns 404 not found for nonexistent items' do
            patch lending_update_path(directory: 'not_a_directory'), params: { lending_item: { active: true, copies: 17 } }
            expect(response.status).to eq(404)
          end
        end
      end

      describe :activate do
        it 'activates an inactive item' do
          item.update!(active: false)

          get lending_activate_path(directory: item.directory) # TODO: use PATCH
          expect(response).to redirect_to index_path

          follow_redirect!
          expect(response.body).to include('Item now active.')

          item.reload
          expect(item.active?).to eq(true)
        end

        it 'is successful for an already active item' do
          get lending_activate_path(directory: item.directory) # TODO: use PATCH
          expect(response).to redirect_to index_path

          follow_redirect!
          expect(response.body).to include('Item already active.')

          item.reload
          expect(item.active?).to eq(true)
        end

        it 'defaults to 1 copy for an item with zero copies' do
          item.update!(active: false, copies: 0)

          get lending_activate_path(directory: item.directory) # TODO: use PATCH
          expect(response).to redirect_to index_path

          follow_redirect!
          expect(response.body).to include('Item now active.')

          item.reload
          expect(item.active?).to eq(true)
          expect(item.copies).to eq(1)
        end

        it 'returns 404 not found for nonexistent items' do
          get lending_activate_path(directory: 'not_a_directory')
          expect(response.status).to eq(404)
        end
      end

      describe :deactivate do
        it 'deactivates an active item' do
          get lending_deactivate_path(directory: item.directory) # TODO: use PATCH
          expect(response).to redirect_to index_path

          follow_redirect!
          expect(response.body).to include('Item now inactive.')

          item.reload
          expect(item.active?).to eq(false)
        end

        it 'is successful even for an already inactive item' do
          item.update!(active: false)

          get lending_deactivate_path(directory: item.directory) # TODO: use PATCH

          expect(response).to redirect_to index_path

          follow_redirect!
          expect(response.body).to include('Item already inactive.')

          item.reload
          expect(item.active?).to eq(false)
        end

        it 'expires any checkouts' do
          loan = item.check_out_to!('patron-1')

          get lending_deactivate_path(directory: item.directory) # TODO: use PATCH
          follow_redirect!
          expect(response.body).to include('Item now inactive.')

          loan.reload
          expect(loan.active?).to eq(false)

          expect(item.lending_item_loans.active).to be_empty
        end

        it 'returns 404 not found for nonexistent items' do
          get lending_deactivate_path(directory: 'not_a_directory')
          expect(response.status).to eq(404)
        end
      end

      describe :destroy do
        it 'destroys an incomplete item' do
          item = incomplete.first
          expect(item).not_to be_complete # just to be sure

          delete lending_destroy_path(directory: item.directory)

          expect(response).to redirect_to index_path

          follow_redirect!
          expect(response.body).to include('Item deleted.')

          expect { LendingItem.find(item.id) }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'does not destroy a complete item' do
          allow(Rails.logger).to receive(:warn)

          expect(item).to be_complete # just to be sure
          expect(Rails.logger).to receive(:warn).with('Failed to delete non-incomplete item', item.debug_hash)

          delete lending_destroy_path(directory: item.directory)
          expect(response).to redirect_to index_path

          follow_redirect!
          expect(response.body).to include('Only incomplete items can be deleted.')

          expect(LendingItem.find(item.id)).to eq(item)
        end

        it 'returns 404 not found for nonexistent items' do
          get lending_destroy_path(directory: 'not_a_directory')
          expect(response.status).to eq(404)
        end
      end

      describe :reload do
        it 'reloads the MARC metadata' do
          original_author = item.author
          edited_author = 'Roe, Rachel R.'
          expect(edited_author).not_to eq(original_author) # just to be sure

          item.update!(author: edited_author)

          get lending_reload_path(directory: item.directory)
          expect(response).to redirect_to lending_show_path(directory: item.directory)

          follow_redirect!
          expect(response.body).to include('MARC metadata reloaded.')

          item.reload
          expect(item.author).to eq(original_author)
        end

        it 'returns 404 not found for nonexistent items' do
          get lending_reload_path(directory: 'not_a_directory')
          expect(response.status).to eq(404)
        end

        it 'succeeds for unchanged items' do
          get lending_reload_path(directory: item.directory)
          expect(response).to redirect_to lending_show_path(directory: item.directory)

          follow_redirect!
          expect(response.body).to include('No changes found.')
        end

        it 'shows an error for items without MARC metadata' do
          item = incomplete.find { |it| !it.has_marc_record? }
          expect(item).not_to be_nil # just to be sure

          get lending_reload_path(directory: item.directory)
          expect(response).to redirect_to lending_show_path(directory: item.directory)
          follow_redirect!
          expect(response.body).to include('Error reloading MARC metadata')
        end
      end
    end
  end

  describe 'with patron credentials' do
    attr_reader :user, :item

    before(:each) do
      @user = mock_login(:student)
      expect(LendingItem.count).to eq(0) # just to be sure
      # NOTE: we're deliberately not validating here, because we want some invalid items
      @items = factory_names.each_with_object({}) do |fn, items|
        items[fn] = build(fn).tap { |it| it.save!(validate: false) }
      end
      @item = available.first
    end

    after(:each) { logout! }

    describe :show do
      it 'returns 403 Forbidden' do
        get lending_show_path(directory: item.directory)
        expect(response.status).to eq(403)
      end

      it 'returns 403 forbidden even for nonexistent items' do
        get lending_deactivate_path(directory: 'not_a_directory')
        expect(response.status).to eq(403)
      end
    end

    describe :view do
      context 'without an explicit token' do
        it "doesn't create a new loan record" do
          expect do
            get lending_view_path(directory: item.directory)
          end.not_to change(LendingItemLoan, :count)

          expect(response).to be_successful
          expect(response.body).to include('Check out')
          expect(response.body).not_to include('Return')
        end

        it 'returns 404 not found for nonexistent items' do
          get lending_view_path(directory: 'not_a_directory')
          expect(response.status).to eq(404)
        end

        it 'shows a loan if one exists' do
          loan = item.check_out_to!(user.borrower_id)
          expect(loan.errors.full_messages).to be_empty
          expect(loan).to be_persisted # just to be sure

          expect do
            get lending_view_path(directory: item.directory)
          end.not_to change(LendingItemLoan, :count)

          expected_path = lending_view_path(directory: item.directory, token: user.borrower_token.token_str)
          expect(response).to redirect_to(expected_path)
          follow_redirect!

          body = response.body

          # TODO: format all dates
          due_date_str = item.next_due_date.to_s(:short)
          expect(body).to include(due_date_str)

          expect(body).not_to include('Check out')
          expect(body).to include('Return now')
        end

        it 'pre-returns the loan if already expired' do
          loan_date = Time.current - 3.weeks
          due_date = loan_date + LendingItem::LOAN_DURATION_SECONDS.seconds
          loan = LendingItemLoan.create(
            lending_item_id: item.id,
            patron_identifier: user.borrower_id,
            loan_status: :active,
            loan_date: loan_date,
            due_date: due_date
          )
          loan.reload
          expect(loan.complete?).to eq(true)
          expect(loan.active?).to eq(false)

          expect do
            get lending_view_path(directory: item.directory)
          end.not_to change(LendingItemLoan, :count)
          expect(response).to be_successful

          loan.reload
          expect(loan).to be_complete
          expect(loan.return_date).to be_within(1.minute).of Time.current

          body = response.body

          # TODO: format all dates
          return_date_str = loan.return_date.to_s(:short)
          expect(body).to include(return_date_str)

          expect(body).to include('Check out')
          expect(body).not_to include('Return now')
        end

        it 'pre-returns the loan if the number of copies is changed to zero' do
          loan = item.check_out_to!(user.borrower_id)

          item.update!(copies: 0, active: false)

          loan.reload
          expect(loan.complete?).to eq(true)
          expect(loan.active?).to eq(false)

          expect do
            get lending_view_path(directory: item.directory)
          end.not_to change(LendingItemLoan, :count)
          expect(response).to be_successful

          loan.reload
          expect(loan).to be_complete
          expect(loan.return_date).to be_within(1.minute).of Time.current

          body = response.body

          # TODO: format all dates
          return_date_str = loan.return_date.to_s(:short)
          expect(body).to include(return_date_str)

          expect(body).to include('Check out')
          expect(body).not_to include('Return now')
        end

        it 'displays an item with no available copies' do
          item.copies.times do |copy|
            item.check_out_to!("patron-#{copy}")
          end
          expect(item).not_to be_available # just to be sure

          expect do
            get lending_view_path(directory: item.directory)
          end.not_to change(LendingItemLoan, :count)
          expect(response).to be_successful

          body = response.body
          # TODO: verify checkout disabled
          expect(body).not_to include('Return now')
          expect(body).to include(LendingItem::MSG_UNAVAILABLE)

          # TODO: format all dates
          due_date_str = item.next_due_date.to_s(:long)
          expect(body).to include(due_date_str)
        end
      end
    end

    describe :check_out do
      it 'checks out an item' do
        # TODO: share these assertions
        expect do
          get lending_check_out_path(directory: item.directory)
        end.to change(LendingItemLoan, :count).by(1)

        loan = LendingItemLoan.find_by(
          lending_item_id: item.id,
          patron_identifier: user.borrower_id
        )
        expect(loan).to be_active
        expect(loan.loan_date).to be <= Time.current
        expect(loan.due_date).to be > Time.current
        expect(loan.due_date - loan.loan_date).to eq(LendingItem::LOAN_DURATION_SECONDS.seconds)

        expected_path = lending_view_path(directory: item.directory, token: user.borrower_token.token_str)
        expect(response).to redirect_to(expected_path)

        expect(response.body).not_to include(LendingItem::MSG_CHECKOUT_LIMIT_REACHED)
      end

      it 'returns 404 not found for nonexistent items' do
        get lending_check_out_path(directory: 'not_a_directory')
        expect(response.status).to eq(404)
      end

      it 'fails if this user has already checked out the item' do
        loan = item.check_out_to!(user.borrower_id)
        expect(loan).to be_persisted

        expect do
          get lending_check_out_path(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)

        expect(response.status).to eq(422) # unprocessable entity
        expect(response.body).to include(LendingItem::MSG_CHECKED_OUT)
      end

      context 'checkout limits' do
        before(:each) do
          # make sure we actually have multiple possible checkouts
          inactive.each { |it| it.update!(copies: 2, active: true) }
        end

        it 'fails if this user has already hit the checkout limit' do
          max_checkouts = LendingItem::MAX_CHECKOUTS_PER_PATRON
          expect(active.size).to be > max_checkouts # just to be sure
          max_checkouts.times { |i| active[i].check_out_to!(user.borrower_id) }
          item = active[max_checkouts] # next active item

          expect do
            get lending_check_out_path(directory: item.directory)
          end.not_to change(LendingItemLoan, :count)

          expect(response.status).to eq(422) # unprocessable entity
          expect(response.body).to include(LendingItem::MSG_CHECKOUT_LIMIT_REACHED)
        end

        it 'allows a checkout if the user previously checked something out, but returned it' do
          max_checkouts = LendingItem::MAX_CHECKOUTS_PER_PATRON
          expect(active.size).to be > max_checkouts # just to be sure
          max_checkouts.times do |i|
            loan = active[i].check_out_to!(user.borrower_id)
            loan.return!
          end

          item = active[max_checkouts] # next active item

          # TODO: share these assertions
          expect do
            get lending_check_out_path(directory: item.directory)
          end.to change(LendingItemLoan, :count).by(1)

          loan = LendingItemLoan.find_by(
            lending_item_id: item.id,
            patron_identifier: user.borrower_id
          )
          expect(loan).to be_active
          expect(loan.loan_date).to be <= Time.current
          expect(loan.due_date).to be > Time.current
          expect(loan.due_date - loan.loan_date).to eq(LendingItem::LOAN_DURATION_SECONDS.seconds)

          expected_path = lending_view_path(directory: item.directory, token: user.borrower_token.token_str)
          expect(response).to redirect_to(expected_path)

          expect(response.body).not_to include(LendingItem::MSG_CHECKOUT_LIMIT_REACHED)
        end

        it 'allows a checkout if the user previously checked something out, but it was auto-returned' do
          max_checkouts = LendingItem::MAX_CHECKOUTS_PER_PATRON
          expect(active.size).to be > max_checkouts # just to be sure
          max_checkouts.times do |i|
            loan = active[i].check_out_to!(user.borrower_id)
            loan.due_date = Time.current.utc - 1.days
            loan.save!
          end

          item = active[max_checkouts] # next active item

          # TODO: share these assertions
          expect do
            get lending_check_out_path(directory: item.directory)
          end.to change(LendingItemLoan, :count).by(1)

          loan = LendingItemLoan.find_by(
            lending_item_id: item.id,
            patron_identifier: user.borrower_id
          )
          expect(loan).to be_active
          expect(loan.loan_date).to be <= Time.current
          expect(loan.due_date).to be > Time.current
          expect(loan.due_date - loan.loan_date).to eq(LendingItem::LOAN_DURATION_SECONDS.seconds)

          expected_path = lending_view_path(directory: item.directory, token: user.borrower_token.token_str)
          expect(response).to redirect_to(expected_path)

          expect(response.body).not_to include(LendingItem::MSG_CHECKOUT_LIMIT_REACHED)
        end
      end

      it 'fails if there are no copies available' do
        item.copies.times do |copy|
          item.check_out_to!("patron-#{copy}")
        end
        expect(item).not_to be_available

        expect do
          get lending_check_out_path(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)

        expect(response.status).to eq(422) # unprocessable entity
        expect(response.body).to include(LendingItem::MSG_UNAVAILABLE)
      end

      it 'fails if the item is not active' do
        item.update!(active: false)

        expect do
          get lending_check_out_path(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)

        expect(response.status).to eq(422) # unprocessable entity
        expect(response.body).to include(LendingItem::MSG_INACTIVE)
      end
    end

    describe :return do
      it 'returns an item' do
        loan = item.check_out_to!(user.borrower_id)
        get lending_return_path(directory: item.directory)

        loan.reload
        expect(loan).to be_complete

        expected_path = lending_view_path(directory: item.directory)
        expect(response).to redirect_to(expected_path)
      end

      it 'succeeds even if the item was already returned' do
        loan = item.check_out_to!(user.borrower_id)
        loan.return!

        get lending_return_path(directory: item.directory)
        expected_path = lending_view_path(directory: item.directory)
        expect(response).to redirect_to(expected_path)
      end

      it 'succeeds even if the item was never checked out' do
        expect do
          get lending_return_path(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)
        expected_path = lending_view_path(directory: item.directory)
        expect(response).to redirect_to(expected_path)
      end

      it 'returns 404 not found for nonexistent items' do
        get lending_return_path(directory: 'not_a_directory')
        expect(response.status).to eq(404)
      end

    end

    describe :manifest do
      it 'returns the manifest for a checked-out item' do
        item.check_out_to!(user.borrower_id)
        get lending_manifest_path(directory: item.directory)
        expect(response).to be_successful
      end

      it 'returns 403 Forbidden if the item has not been checked out' do
        get lending_manifest_path(directory: item.directory)
        expect(response.status).to eq(403)
      end

      it 'returns 404 not found for nonexistent items' do
        get lending_manifest_path(directory: 'not_a_directory')
        expect(response.status).to eq(404)
      end
    end

    describe :edit do
      it 'returns 403 forbidden' do
        get lending_edit_path(directory: item.directory)
        expect(response.status).to eq(403)
      end

      it 'returns 403 forbidden even for nonexistent items' do
        get lending_edit_path(directory: 'not_a_directory')
        expect(response.status).to eq(403)
      end
    end

    describe :activate do
      it 'returns 403 forbidden' do
        get lending_activate_path(directory: item.directory)
        expect(response.status).to eq(403)
      end

      it "doesn't activate the item" do
        item.update!(active: false)

        get lending_activate_path(directory: item.directory)

        item.reload
        expect(item.active).to eq(false)
      end

      it 'returns 403 forbidden even for nonexistent items' do
        get lending_activate_path(directory: 'not_a_directory')
        expect(response.status).to eq(403)
      end
    end

    describe :inactivate do
      it 'returns 403 forbidden' do
        get lending_deactivate_path(directory: item.directory)
        expect(response.status).to eq(403)

        item.reload
        expect(item.active).to eq(true)
      end

      it 'returns 403 forbidden even for nonexistent items' do
        get lending_deactivate_path(directory: 'not_a_directory')
        expect(response.status).to eq(403)
      end
    end

    describe :reload do
      it 'returns 403 forbidden' do
        get lending_reload_path(directory: item.directory)
        expect(response.status).to eq(403)
      end

      it "doesn't reload the MARC metadata" do
        original_author = item.author
        edited_author = 'Roe, Rachel R.'
        expect(edited_author).not_to eq(original_author) # just to be sure

        item.update!(author: edited_author)
        get lending_reload_path(directory: item.directory)
        item.reload
        expect(item.author).to eq(edited_author)
      end

      it 'returns 403 forbidden even for nonexistent items' do
        get lending_reload_path(directory: 'not_a_directory')
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'without login' do
    before(:each) do
      @item = create(:item)
    end

    it 'GET lending_manifest_path redirects to login' do
      get(path = lending_manifest_path(directory: item.directory))
      login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: path)}"
      expect(response).to redirect_to(login_with_callback_url)
    end

    it 'GET lending_edit_path redirects to login' do
      get(path = lending_edit_path(directory: item.directory))
      login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: path)}"
      expect(response).to redirect_to(login_with_callback_url)
    end

    it 'GET lending_view_path redirects to login' do
      get(path = lending_view_path(directory: item.directory))
      login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: path)}"
      expect(response).to redirect_to(login_with_callback_url)
    end

    it 'GET lending_show_path redirects to login' do
      get(path = lending_show_path(directory: item.directory))
      login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: path)}"
      expect(response).to redirect_to(login_with_callback_url)
    end

    it 'DELETE lending_destroy_path redirects to login' do
      delete(path = lending_destroy_path(directory: item.directory))
      login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: path)}"
      expect(response).to redirect_to(login_with_callback_url)
    end

    # TODO: use PATCH
    it 'GET lending_activate_path redirects to login' do
      get(path = lending_activate_path(directory: item.directory))
      login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: path)}"
      expect(response).to redirect_to(login_with_callback_url)
    end

    # TODO: use PATCH
    it 'GET lending_deactivate_path redirects to login' do
      get(path = lending_deactivate_path(directory: item.directory))
      login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: path)}"
      expect(response).to redirect_to(login_with_callback_url)
    end
  end

  describe 'with ineligible patron' do
    before(:each) do
      @item = create(:item)
      mock_login(:retiree)
    end

    after(:each) { logout! }

    it 'GET lending_manifest_path returns 403 Forbidden' do
      get lending_manifest_path(directory: item.directory)
      expect(response.status).to eq(403)
    end

    it 'GET lending_edit_path returns 403 Forbidden' do
      get lending_edit_path(directory: item.directory)
      expect(response.status).to eq(403)
    end

    it 'GET lending_view_path returns 403 Forbidden' do
      get lending_view_path(directory: item.directory)
      expect(response.status).to eq(403)
    end

    it 'DELETE lending_destroy_path returns 403 Forbidden' do
      delete lending_destroy_path(directory: item.directory)
      expect(response.status).to eq(403)
    end

    # TODO: use PATCH
    it 'GET lending_activate_path returns 403 Forbidden' do
      get lending_activate_path(directory: item.directory)
      expect(response.status).to eq(403)
    end

    # TODO: use PATCH
    it 'GET lending_deactivate_path returns 403 Forbidden' do
      get lending_deactivate_path(directory: item.directory)
      expect(response.status).to eq(403)
    end
  end
end
