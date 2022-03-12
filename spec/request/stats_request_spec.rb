require 'rails_helper'

RSpec.describe StatsController, type: :request do
  attr_reader :current_term, :users, :items, :loans, :completed_loans, :expired_loans, :returned_loans

  let(:user_types) { %i[staff faculty student lending_admin] }

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

    @users = user_types.map { |t| mock_user_without_login(t) }

    # TODO: share code among stats_presenter_spec, item_lending_stats_spec, stats_request_spec
    copies_per_item = 2 * users.size

    @items = %i[active_item complete_item].map do |f|
      create(f, copies: copies_per_item, active: true)
    end

    @returned_loans = []

    @loans = []
    users.each do |user|
      loans << create(:active_loan, item_id: items[0].id, patron_identifier: user.borrower_id)
      loans << create(:expired_loan, item_id: items[0].id, patron_identifier: user.borrower_id)
      loans << create(:completed_loan, item_id: items[1].id, patron_identifier: user.borrower_id)
    end

    @returned_loans = loans.select(&:return_date)
    expect(returned_loans).not_to be_empty # just to be sure

    @expired_loans = loans.select(&:expired?)
    expect(expired_loans).not_to be_empty # just to be sure

    @completed_loans = loans.select(&:complete?)
    expect(completed_loans).not_to be_empty # just to be sure

    expect(completed_loans).to match_array(returned_loans + expired_loans) # just to be sure
  end

  after do
    Settings.default_term = @prev_default_term
  end

  context 'with lending admin credentials' do
    before { mock_login(:lending_admin) }

    describe :index do
      it 'displays the stats' do
        get stats_path
        expect(response).to be_successful
      end
    end

    describe :stats_profile do
      let(:profile_file) { File.join('public', StatsController::PROFILE_STATS_HTML) }

      it 'generates a profile' do
        get stats_profile_path

        expect(File.exist?(profile_file)).to eq(true)

        get "/#{StatsController::PROFILE_STATS_HTML}"
        expect(response).to be_successful
      ensure
        FileUtils.rm_f(profile_file)
      end

      it 'does something sensible in the event of a failure' do
        allow(StatsPresenter).to receive(:new).and_raise('Oops')

        get stats_profile_path
        expect(response.body).to include('Error generating profile')
      ensure
        FileUtils.rm_f(profile_file)
      end
    end

    describe :download do
      context 'without a date' do
        it 'returns stats for all loans' do
          get stats_download_path
          expect(response).to be_successful

          body_csv = CSV.parse(response.body, headers: true)
          expect(body_csv.headers).to eq(ItemLendingStats::CSV_HEADERS)
          # TODO: test content
        end
      end

      context 'with a date' do
        it 'returns the stats for the specified date' do
          ItemLendingStats.all_loan_dates.each do |date|
            get stats_download_path(date: date.iso8601)

            expect(response).to be_successful

            body_csv = CSV.parse(response.body, headers: true)
            expect(body_csv.headers).to eq(ItemLendingStats::CSV_HEADERS)
            # TODO: test content
          end
        end

        it 'rejects a non-date argument' do
          get stats_download_path(date: 'not a date')
          expect(response.status).to eq(400)
          expect(response.body).to be_empty
        end

        it 'rejects a bad date' do
          get stats_download_path(date: '9999-99-99')
          expect(response.status).to eq(400)
          expect(response.body).to be_empty
        end
      end
    end
  end
end
