require 'rails_helper'

describe ItemLendingStats do
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
  end
end
