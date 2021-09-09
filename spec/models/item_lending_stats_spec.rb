require 'rails_helper'

describe ItemLendingStats do
  def date_failure_msg(actual_date, expected_date, id)
    stmt = ActiveRecord::Base.sanitize_sql([select_loan_date, id])
    {
      id: id,
      expected: expected_date,
      actual: actual_date,
      rails: LendingItemLoan.find(id).loan_date,
      db: ActiveRecord::Base.connection.exec_query(stmt).first['loan_date']
    }.map { |k, v| "#{k}: #{v}" }.join('; ')
  end

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
    let(:select_loan_date) { 'select loan_date from lending_item_loans where id = ?' }

    attr_reader :loans_by_date

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

      @loans_by_date = {}
      LendingItemLoan.pluck(:id, :loan_date).each do |id, loan_date|
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

      it 'returns the correct date for each loan' do
        aggregate_failures 'all_loan_dates_by_id' do
          failure_count = 0
          ItemLendingStats.all_loan_dates_by_id.each do |id, actual_date|
            expected_date = loans_by_date[id]

            failure_count += 1 if actual_date != expected_date
            expect(actual_date).to eq(expected_date), -> { "Wrong date: #{date_failure_msg(actual_date, expected_date, id)}" }
          end

          if failure_count > 0
            tzs = {
              db: ActiveRecord::Base.connection.exec_query("select current_setting('TIMEZONE') as tz").first['tz'],
              system: Time.now.zone,
              rails: Time.zone
            }.map { |tz_type, tz_value| "#{tz_type}: #{tz_value}" }.join(', ')
            RSpec::Expectations.fail_with("#{failure_count} loans returned incorrect dates; time zones were: #{tzs}")
          end
        end
      end
    end

    describe :each_by_date do
      it 'returns each loan in the correct date group' do
        aggregate_failures 'all_loan_dates_by_id' do
          failure_count = 0
          ItemLendingStats.each_by_date do |expected_date, stats_for_date|
            stats_for_date.each do |item_stats|
              item_stats.loans.each do |loan|
                loan_date = loan.loan_date

                actual_date = loan_date.to_date
                failure_count += 1 if actual_date != expected_date
                expect(actual_date).to eq(expected_date), -> { "Wrong date group: #{date_failure_msg(actual_date, expected_date, loan.id)}" }
              end
            end
          end

          if failure_count > 0
            tzs = {
              db: ActiveRecord::Base.connection.exec_query("select current_setting('TIMEZONE') as tz").first['tz'],
              system: Time.now.zone,
              rails: Time.zone
            }.map { |tz_type, tz_value| "#{tz_type}: #{tz_value}" }.join(', ')
            RSpec::Expectations.fail_with("#{failure_count} loans in incorrect group; time zones were: #{tzs}")
          end
        end
      end
    end
  end
end
