require 'rails_helper'

describe LendingItemLoan do
  attr_reader :borrower_id
  attr_reader :user
  attr_reader :item

  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://ucbears-iiif/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end

    @user = mock_user_without_login(:student)
    @borrower_id = user.borrower_id

    @item = create(:active_item)
  end

  describe 'validations' do
    it 'prevents duplicate checkouts' do
      loan = item.check_out_to!(user.borrower_id)
      expect(loan).to be_persisted # just to be sure

      expect { item.check_out_to!(user.borrower_id) }.to raise_error(ArgumentError, LendingItem::MSG_CHECKED_OUT)
    end
  end

  describe :return! do
    attr_reader :loan

    before(:each) do
      @loan = item.check_out_to(borrower_id)
      expect(item.copies_available).to eq(item.copies - 1) # just to be sure
    end

    it 'returns the item' do
      loan.return!
      expect(item.copies_available).to eq(item.copies)
    end
  end

  describe :duration do
    attr_reader :loan

    before(:each) do
      @loan = item.check_out_to(borrower_id).tap do |l|
        l.update!(loan_date: l.loan_date - 30.minutes)
      end
    end

    it 'returns nil for active items' do
      expect(loan.duration).to be_nil
    end

    it 'returns the loan duration' do
      loan.return!
      expect(loan.duration).to eq(loan.return_date - loan.loan_date)
    end

    it 'works for expired items' do
      loan.update!(due_date: loan.loan_date + 15.minutes)
      expect(loan.duration).to eq(15.minutes)
    end
  end
end
