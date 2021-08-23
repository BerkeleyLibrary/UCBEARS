require 'rails_helper'

describe LendingItemLoan do
  attr_reader :patron_id

  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://ucbears-iiif/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end

    user = mock_user_without_login(:student)
    @patron_id = user.lending_id
  end

  describe :return! do
    attr_reader :item
    attr_reader :loan

    before(:each) do
      @item = create(:active_item)
      @loan = item.check_out_to(patron_id)
      expect(item.copies_available).to eq(item.copies - 1) # just to be sure
    end

    it 'returns the item' do
      loan.return!
      expect(item.copies_available).to eq(item.copies)
    end

    xit 'sets the item to a placeholder' do
      addl_loan_obj = LendingItemLoan.find_by!(lending_item: item)
      expect(addl_loan_obj).to eq(loan) # just to be sure

      loan.return!
      expect(loan.lending_item).to eq(LendingItem.returned_placeholder)

      expet(addl_loan_obj.lending_item).to eq(item)
      addl_loan_obj.reload
      expect(addl_loan_obj.lending_item).to eq(LendingItem.returned_placeholder)
    end
  end
end
