require 'calnet_helper'

describe LendingController, type: :request do
  before(:each) do
    allow(Rails.application.config).to receive(:iiif_final_dir).and_return('spec/data/lending/samples/final')
  end

  let(:valid_item_attributes) do
    [
      {
        title: 'The Plan of St. Gall : a study of the architecture & economy of life in a paradigmatic Carolingian monastery',
        author: 'Horn, Walter',
        directory: 'b100523250_C044235662',
        copies: 1,
        active: true
      },
      {
        title: 'The great depression in Europe, 1929-1939',
        author: 'Clavin, Patricia.',
        directory: 'b135297126_C068087930',
        copies: 2,
        active: true
      },
      {
        title: 'Villette',
        author: 'Brontë, Charlotte',
        directory: 'b155001346_C044219363',
        copies: 0,
        active: false
      }
    ]
  end

  attr_reader :items
  attr_reader :item

  def active
    items.select(&:active?)
  end

  def complete
    items.select(&:complete?)
  end

  def incomplete
    items.reject(&:complete?)
  end

  after(:each) { logout! }

  context 'with lending admin credentials' do
    before(:each) { mock_calnet_login(CalNet::LENDING_ADMIN_UID) }

    context 'without any items' do
      describe :index do
        it 'shows an empty list' do
          get lending_path
          expect(response).to be_successful
        end
      end

      describe :new do
        it 'displays the form' do
          get lending_new_path
          expect(response).to be_successful
          expect(response.body).to include(lending_path)
        end
      end

      describe :create do
        it 'creates items' do
          valid_item_attributes.each do |item_attributes|
            expect do
              post lending_path, params: { lending_item: item_attributes }
            end.to change(LendingItem, :count).by(1)

            directory = item_attributes[:directory]
            expect(response).to redirect_to lending_show_path(directory: directory)

            item = LendingItem.find_by(directory: directory)
            expect(item).not_to be_nil

            item_attributes.each do |attr, val|
              expect(item.send(attr)).to eq(val)
              expect(item.copies_available).to eq(item.copies)
            end
          end
        end

        describe 'with invalid attributes' do
          let(:invalid_item_attributes) do
            valid_attributes = valid_item_attributes[0]
            [].tap do |invalid_item_attributes|
              %i[directory title author].each do |attr|
                invalid_attributes = valid_attributes.dup
                invalid_attributes.delete(attr)
                invalid_item_attributes << invalid_attributes
              end

              invalid_attributes = valid_attributes.dup
              invalid_attributes[:copies] = -1
              invalid_item_attributes << invalid_attributes
            end
          end

          it 'does not create items' do
            invalid_item_attributes.each do |item_attributes|
              expect { post lending_path, params: { lending_item: item_attributes } }
                .not_to change(LendingItem, :count)
              expect(response.status).to eq(422) # unprocessable entity
            end
          end
        end
      end
    end

    context 'with items' do
      before(:each) do
        @items = valid_item_attributes.map do |item_attributes|
          LendingItem.create!(**item_attributes)
        end
        @item = items.first
      end

      describe :index do
        it 'lists the items' do
          get lending_path
          expect(response).to be_successful

          body = response.body
          items.each do |item|
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

          get lending_path
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

          get lending_path
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

      describe :show do
        it 'shows an item' do
          items.each do |item|
            get lending_show_path(directory: item.directory)
            expect(response).to be_successful
          end
        end

        xit 'only shows the viewer for complete items'
        xit 'shows a message for incomplete items'
      end

      describe :edit do
        it 'displays the form' do
          items.each do |item|
            get lending_edit_path(directory: item.directory)
            expect(response).to be_successful
            update_path = lending_update_path(directory: item.directory)
            expect(response.body).to include(update_path)
          end
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
      end

      describe :update do
        let(:new_attributes) do
          {
            copies: 2
          }
        end

        it 'updates an item' do
          items.each do |item|
            directory = item.directory

            expect do
              patch lending_update_path(directory: directory), params: { lending_item: new_attributes }
            end.not_to change(LendingItem, :count)

            expect(response).to redirect_to lending_show_path(directory: directory)

            item.reload
            new_attributes.each { |attr, val| expect(item.send(attr)).to eq(val) }
          end
        end
      end

      describe :activate do
        it 'activates an inactive item' do
          item.update!(active: false)

          get lending_activate_path(directory: item.directory) # TODO: use PATCH
          expect(response).to redirect_to lending_path

          follow_redirect!
          expect(response.body).to include('Item now active.')

          item.reload
          expect(item.active?).to eq(true)
        end

        it 'is successful for an already active item' do
          get lending_activate_path(directory: item.directory) # TODO: use PATCH
          expect(response).to redirect_to lending_path

          follow_redirect!
          expect(response.body).to include('Item already active.')

          item.reload
          expect(item.active?).to eq(true)
        end

        it 'defaults to 1 copy for an item with zero copies' do
          item.update!(active: false, copies: 0)

          get lending_activate_path(directory: item.directory) # TODO: use PATCH
          expect(response).to redirect_to lending_path

          follow_redirect!
          expect(response.body).to include('Item now active.')

          item.reload
          expect(item.active?).to eq(true)
          expect(item.copies).to eq(1)
        end
      end

      describe :deactivate do
        it 'deactivates an active item' do
          get lending_deactivate_path(directory: item.directory) # TODO: use PATCH
          expect(response).to redirect_to lending_path

          follow_redirect!
          expect(response.body).to include('Item now inactive.')

          item.reload
          expect(item.active?).to eq(false)
        end

        it 'is successful even for an already inactive item' do
          item.update!(active: false)

          get lending_deactivate_path(directory: item.directory) # TODO: use PATCH

          expect(response).to redirect_to lending_path

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
      end

      describe :destroy do
        it 'destroys an incomplete item' do
          item = incomplete.first
          expect(item).not_to be_complete # just to be sure

          delete lending_destroy_path(directory: item.directory)

          expect(response).to redirect_to lending_path

          follow_redirect!
          expect(response.body).to include('Item deleted.')

          expect { LendingItem.find(item.id) }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'does not destroy a complete item' do
          expect(item).to be_complete # just to be sure

          delete lending_destroy_path(directory: item.directory)
          expect(response).to redirect_to lending_path

          follow_redirect!
          expect(response.body).to include('Only incomplete items can be deleted.')

          expect(LendingItem.find(item.id)).to eq(item)
        end
      end
    end
  end

  describe 'with patron credentials' do
    attr_reader :user, :item

    before(:each) do
      patron_id = Patron::Type.sample_id_for(Patron::Type::UNDERGRAD)
      @user = login_as_patron(patron_id)
      @items = valid_item_attributes.map do |item_attributes|
        LendingItem.create!(**item_attributes)
      end
      @item = items.find(&:available?)
    end

    describe :show do
      it 'returns 403 Forbidden' do
        get lending_show_path(directory: item.directory)
        expect(response.status).to eq(403)
      end
    end

    describe :view do
      it "doesn't create a new loan record" do
        expect do
          get lending_view_path(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)
        expect(response.body).to include('Check out')
        expect(response.body).not_to include('Return')
        expect(response).to be_successful
      end

      it 'shows a loan if one exists' do
        loan = item.check_out_to!(user.lending_id)
        expect(loan.errors.full_messages).to be_empty
        expect(loan).to be_persisted # just to be sure

        expect do
          get lending_view_path(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)
        expect(response).to be_successful

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
          patron_identifier: user.lending_id,
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
        loan = item.check_out_to!(user.lending_id)

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

    describe :check_out do
      it 'checks out an item' do
        # TODO: share these assertions
        expect do
          get lending_check_out_path(directory: item.directory)
        end.to change(LendingItemLoan, :count).by(1)

        loan = LendingItemLoan.find_by(
          lending_item_id: item.id,
          patron_identifier: user.lending_id
        )
        expect(loan).to be_active
        expect(loan.loan_date).to be <= Time.current
        expect(loan.due_date).to be > Time.current
        expect(loan.due_date - loan.loan_date).to eq(LendingItem::LOAN_DURATION_SECONDS.seconds)

        expected_path = lending_view_path(directory: item.directory)
        expect(response).to redirect_to(expected_path)

        expect(response.body).not_to include(LendingItem::MSG_CHECKOUT_LIMIT_REACHED)
      end

      it 'fails if this user has already checked out the item' do
        loan = item.check_out_to!(user.lending_id)
        expect(loan).to be_persisted

        expect do
          get lending_check_out_path(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)

        expect(response.status).to eq(422) # unprocessable entity
        expect(response.body).to include(LendingItem::MSG_CHECKED_OUT)
      end

      it 'fails if this user has already hit the checkout limit' do
        max_checkouts = LendingItem::MAX_CHECKOUTS_PER_PATRON
        expect(active.size).to be > max_checkouts # just to be sure
        max_checkouts.times { |i| active[i].check_out_to!(user.lending_id) }
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
          loan = active[i].check_out_to!(user.lending_id)
          loan.return!
        end

        item = active[max_checkouts] # next active item

        # TODO: share these assertions
        expect do
          get lending_check_out_path(directory: item.directory)
        end.to change(LendingItemLoan, :count).by(1)

        loan = LendingItemLoan.find_by(
          lending_item_id: item.id,
          patron_identifier: user.lending_id
        )
        expect(loan).to be_active
        expect(loan.loan_date).to be <= Time.current
        expect(loan.due_date).to be > Time.current
        expect(loan.due_date - loan.loan_date).to eq(LendingItem::LOAN_DURATION_SECONDS.seconds)

        expected_path = lending_view_path(directory: item.directory)
        expect(response).to redirect_to(expected_path)

        expect(response.body).not_to include(LendingItem::MSG_CHECKOUT_LIMIT_REACHED)
      end

      it 'allows a checkout if the user previously checked something out, but it was auto-returned' do
        max_checkouts = LendingItem::MAX_CHECKOUTS_PER_PATRON
        expect(active.size).to be > max_checkouts # just to be sure
        max_checkouts.times do |i|
          loan = active[i].check_out_to!(user.lending_id)
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
          patron_identifier: user.lending_id
        )
        expect(loan).to be_active
        expect(loan.loan_date).to be <= Time.current
        expect(loan.due_date).to be > Time.current
        expect(loan.due_date - loan.loan_date).to eq(LendingItem::LOAN_DURATION_SECONDS.seconds)

        expected_path = lending_view_path(directory: item.directory)
        expect(response).to redirect_to(expected_path)

        expect(response.body).not_to include(LendingItem::MSG_CHECKOUT_LIMIT_REACHED)
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
        loan = item.check_out_to!(user.lending_id)
        get lending_return_path(directory: item.directory)

        loan.reload
        expect(loan).to be_complete

        expected_path = lending_view_path(directory: item.directory)
        expect(response).to redirect_to(expected_path)
      end

      it 'succeeds even if the item was already returned' do
        loan = item.check_out_to!(user.lending_id)
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
    end

    describe :manifest do
      it 'returns the manifest for a checked-out item' do
        item.check_out_to!(user.lending_id)
        get lending_manifest_path(directory: item.directory)
        expect(response).to be_successful
      end

      it 'returns 403 Forbidden if the item has not been checked out' do
        get lending_manifest_path(directory: item.directory)
        expect(response.status).to eq(403)
      end
    end

    describe :new do
      it 'returns 403 forbidden' do
        get lending_new_path
        expect(response.status).to eq(403)
      end
    end

    describe :edit do
      it 'returns 403 forbidden' do
        get lending_edit_path(directory: item.directory)
        expect(response.status).to eq(403)
      end
    end

    describe :activate do
      it 'returns 403 forbidden' do
        get lending_edit_path(directory: item.directory)
        expect(response.status).to eq(403)
      end

      it "doesn't activate the item" do
        item.update!(active: false)

        get lending_edit_path(directory: item.directory)

        item.reload
        expect(item.active).to eq(false)
      end
    end

    describe :inactivate do
      it 'returns 403 forbidden' do
        get lending_edit_path(directory: item.directory)
        expect(response.status).to eq(403)

        item.reload
        expect(item.active).to eq(true)
      end
    end
  end

  describe 'without login' do
    before(:each) do
      @item = LendingItem.create(**valid_item_attributes.last)
    end

    it 'GET lending_manifest_path redirects to login' do
      get(path = lending_manifest_path(directory: item.directory))
      login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: path)}"
      expect(response).to redirect_to(login_with_callback_url)
    end

    it 'GET lending_new_path redirects to login' do
      get(path = lending_new_path)
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

    xit 'POST endpoints redirects to login'

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
    around(:each) do |example|
      patron_id = Patron::Type.sample_id_for(Patron::Type::VISITING_SCHOLAR)
      with_patron_login(patron_id) { example.run }
    end

    before(:each) do
      @item = LendingItem.create(**valid_item_attributes.last)
    end

    it 'GET lending_manifest_path returns 403 Forbidden' do
      get lending_manifest_path(directory: item.directory)
      expect(response.status).to eq(403)
    end

    it 'GET lending_new_path returns 403 Forbidden' do
      get lending_new_path
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

    xit 'POST endpoints returns 403 Forbidden'

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
