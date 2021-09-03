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

      due_date = ln.loan_date
      loan_date = due_date - LendingItem::LOAN_DURATION_SECONDS.seconds
      return_date = due_date + 1.seconds
      ln.update!(loan_date: loan_date, due_date: due_date, return_date: return_date)
      exp << ln
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
end
