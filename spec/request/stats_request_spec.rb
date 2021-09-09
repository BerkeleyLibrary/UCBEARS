require 'rails_helper'

RSpec.describe StatsController, type: :request do
  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://ucbears-iiif/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

  attr_reader :users, :items, :loans, :completed_loans, :expired_loans, :returned_loans

  let(:user_types) { %i[staff faculty student lending_admin] }

  before(:each) do
    @users = user_types.map { |t| mock_user_without_login(t) }

    # TODO: share code among stats_presenter_spec, item_lending_stats_spec, stats_request_spec
    copies_per_item = 2 * users.size

    @items = %i[active_item complete_item].map do |f|
      create(f, copies: copies_per_item, active: true)
    end

    @returned_loans = []

    @loans = []
    users.each do |user|
      loans << create(:active_loan, lending_item_id: items[0].id, patron_identifier: user.borrower_id)
      loans << create(:expired_loan, lending_item_id: items[0].id, patron_identifier: user.borrower_id)
      loans << create(:completed_loan, lending_item_id: items[1].id, patron_identifier: user.borrower_id)
    end

    @returned_loans = loans.select(&:return_date)
    expect(returned_loans).not_to be_empty # just to be sure

    @expired_loans = loans.select(&:expired?)
    expect(expired_loans).not_to be_empty # just to be sure

    @completed_loans = loans.select(&:complete?)
    expect(completed_loans).not_to be_empty # just to be sure

    expect(completed_loans).to match_array(returned_loans + expired_loans) # just to be sure
  end

  context 'with lending admin credentials' do
    before(:each) { mock_login(:lending_admin) }

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
          # TODO: more explicit error handling
          expect { get stats_download_path(date: 'not a date') }.to raise_error(ActionController::BadRequest)

          # TODO: more explicit error handling
        end

        it 'rejects a bad date' do
          # TODO: more explicit error handling
          expect { get stats_download_path(date: '9999-99-99') }.to raise_error(ActionController::BadRequest)
        end
      end
    end

    describe :all_loan_dates do
      it 'returns all loan dates by ID, as CSV' do
        get stats_all_loan_dates_path

        expected_rails_loan_dates = LendingItemLoan.pluck(:id, :loan_date).to_h

        expected = ItemLendingStats.all_loan_dates_by_id
        expected_headers = expected.columns + ['rails_loan_date']
        expected_rows = expected.rows

        csv = CSV.parse(response.body, headers: true)
        expect(csv.size).to eq(expected_rows.size)

        csv.each_with_index do |csv_row, row|
          expected_values = expected_rows[row]
          expected_values << expected_rails_loan_dates[expected_values[0]]
          expected_headers.each_with_index do |header, col|
            actual = csv_row[header]
            expected = expected_values[col]
            expect(actual.to_s).to eq(expected.to_s)
          end
        end
      end

    end
  end
end
