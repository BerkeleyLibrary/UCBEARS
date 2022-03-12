require 'rails_helper'

describe ItemLendingStats do
  let(:select_loan_date) { 'select loan_date from loans where id = ?' }
  let(:user_types) { %i[staff faculty student lending_admin] }

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
    Settings.default_term = @prev_default_term
  end

  attr_reader :users, :items, :loans, :completed_loans, :expired_loans, :returned_loans

  context 'without loans' do
    describe :all do
      it 'is empty' do
        all_stats = ItemLendingStats.all
        expect(all_stats.any?).to eq(false)
      end
    end

    describe :median_loan_date do
      it 'returns nil' do
        expect(ItemLendingStats.median_loan_duration).to be_nil
      end
    end
  end

  context 'with loans' do
    attr_reader :loans_by_date

    before do
      @users = user_types.map { |t| mock_user_without_login(t) }

      # TODO: share code among stats_presenter_spec, item_lending_stats_spec, stats_request_spec
      copies_per_item = 2 * users.size

      @items = %i[active_item complete_item].map do |f|
        create(f, copies: copies_per_item, active: true)
      end

      @returned_loans = []

      @loans = []
      users.each do |user|
        borrower_id = user.borrower_id
        loans << create(:active_loan, item_id: items[0].id, patron_identifier: borrower_id)

        date = (Date.current - 7.days)
        year, month, day = %i[year month day].map { |attr| date.send(attr) }
        [1, 7, 13, 19].each do |hour|
          expired_loan_date = Time.utc(year, month, day, hour)
          loans << create(:expired_loan, loan_date: expired_loan_date, item_id: items[0].id, patron_identifier: borrower_id)
          completed_loan_date = Time.utc(year, month, day, hour + 3)
          loans << create(:completed_loan, loan_date: completed_loan_date, item_id: items[1].id, patron_identifier: borrower_id)
        end
      end

      @returned_loans = loans.select(&:return_date)
      expect(returned_loans).not_to be_empty # just to be sure

      @expired_loans = loans.select(&:expired?)
      expect(expired_loans).not_to be_empty # just to be sure

      @completed_loans = loans.select(&:complete?)
      expect(completed_loans).not_to be_empty # just to be sure

      expect(completed_loans).to match_array(returned_loans + expired_loans) # just to be sure

      @loans_by_date = {}
      Loan.pluck(:id, :loan_date).each do |id, loan_date|
        loans_by_date[id] = loan_date.to_date
      end
    end

    describe :to_csv do
      it 'returns a CSV' do
        ItemLendingStats.all.each do |stats|
          stats_csv = stats.to_csv
          expect(stats_csv).to be_a(String)

          rows = CSV.parse(stats_csv)
          expect(rows.size).to eq(stats.loan_count_total)
        end
      end
    end

    describe :all_loan_dates do
      it 'returns correct dates based on time zone' do
        expected_loan_dates = loans_by_date.values.sort.uniq.reverse
        all_loan_dates = ItemLendingStats.all_loan_dates

        expect(all_loan_dates).to eq(expected_loan_dates)
      end
    end

    describe :each_by_date do
      it 'returns each loan in the correct date group' do
        aggregate_failures 'each_by_date' do
          ItemLendingStats.each_by_date do |actual_date, stats_for_date|
            stats_for_date.each do |item_stats|
              item_stats.loans.each do |loan|
                loan_date = loan.loan_date

                expected_date = loan_date.to_date
                expect(actual_date).to eq(expected_date), "Loan on date #{loan_date} grouped with #{actual_date}; expected #{expected_date}"
              end
            end
          end
        end
      end

      it 'returns the correct date group even when the Ruby time zone is UTC' do
        tz_actual = ENV['TZ']
        begin
          ENV['TZ'] = 'UTC'

          aggregate_failures 'each_by_date' do
            ItemLendingStats.each_by_date do |actual_date, stats_for_date|
              stats_for_date.each do |item_stats|
                item_stats.loans.each do |loan|
                  loan_date = loan.loan_date

                  expected_date = loan_date.to_date
                  expect(actual_date).to eq(expected_date), "Loan on date #{loan_date} grouped with #{actual_date}; expected #{expected_date}"
                end
              end
            end
          end
        ensure
          ENV['TZ'] = tz_actual
        end
      end
    end
  end
end
