require 'rails_helper'

RSpec.describe 'Stats', type: :request do
  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://ucbears-iiif/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

  attr_reader :users, :items, :loans, :completed_loans, :expired_loans

  let(:user_types) { %i[staff faculty student lending_admin] }

  before(:each) do
    @users = user_types.map { |t| mock_user_without_login(t) }

    @items = %i[active_item complete_item].map do |f|
      create(f).tap do |item|
        item.update!(copies: 2 * users.size, active: true)
      end
    end

    @loans = users.each_with_object([]) do |user, ll|
      items[0].check_out_to(user).tap do |loan|
        loan.return!
        ll << loan
      end
      items[1].check_out_to(user).tap { |loan| ll << loan }
    end

    @completed_loans = loans.select(&:complete?)
    @expired_loans = completed_loans.each_with_object([]).with_index do |(ln, exp), i|
      next if i.even?

      due_date = ln.loan_date - i.days
      loan_date = due_date - LendingItem::LOAN_DURATION_SECONDS.seconds
      return_date = due_date + 1.seconds
      ln.update!(loan_date: loan_date, due_date: due_date, return_date: return_date)
      exp << ln
    end
  end

  context 'with lending admin credentials' do
    before(:each) { mock_login(:lending_admin) }

    describe :lending do
      context 'without a date' do
        it 'returns stats for all loans' do
          get stats_lending_path
          expect(response).to be_successful

          body_csv = CSV.parse(response.body, headers: true)
          expect(body_csv.headers).to eq(ItemLendingStats::CSV_HEADERS)
          # TODO: test content
        end
      end

      context 'with a date' do
        it 'returns the stats for the specified date' do
          ItemLendingStats.all_loan_dates.each do |date|
            get stats_lending_path(date: date.iso8601)

            expect(response).to be_successful

            body_csv = CSV.parse(response.body, headers: true)
            expect(body_csv.headers).to eq(ItemLendingStats::CSV_HEADERS)
            # TODO: test content
          end
        end

        it 'rejects a non-date argument' do
          # TODO: more explicit error handling
          expect { get stats_lending_path(date: 'not a date') }.to raise_error(ActionController::BadRequest)

          # TODO: more explicit error handling
        end

        it 'rejects a bad date' do
          # TODO: more explicit error handling
          expect { get stats_lending_path(date: '9999-99-99') }.to raise_error(ActionController::BadRequest)
        end
      end
    end
  end
end
