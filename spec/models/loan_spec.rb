require 'rails_helper'

describe Loan do
  attr_reader :borrower_id
  attr_reader :user
  attr_reader :item

  attr_reader :current_term

  before do
    @prev_default_term = Settings.default_term
    @current_term = create(:term, name: 'Test 1', start_date: Date.current - 1.days, end_date: Date.current + 1.days)
    Settings.default_term = current_term
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end

    @user = mock_user_without_login(:student)
    @borrower_id = user.borrower_id

    @item = create(:active_item)
  end

  after do
    Settings.default_term = @prev_default_term
  end

  describe 'validations' do
    it 'prevents duplicate checkouts' do
      loan = item.check_out_to!(user.borrower_id)
      expect(loan).to be_persisted # just to be sure

      expect { item.check_out_to!(user.borrower_id) }.to raise_error(ArgumentError, Item::MSG_CHECKED_OUT)
    end
  end

  describe :return! do
    attr_reader :loan

    before do
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

    before do
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

  describe :loaned_on do
    attr_reader :env_tz_actual
    attr_reader :rails_tz_actual
    attr_reader :loans_by_date

    before do
      @env_tz_actual = ENV['TZ']
      @rails_tz_actual = Time.zone

      Time.zone = 'America/Los_Angeles'

      @loans_by_date = {}

      local_date = (Date.current - 7.days)
      year, month, day = %i[year month day].map { |attr| local_date.send(attr) }
      [2, 8, 14, 20].each do |hour|
        loan_date = Time.zone.local(year, month, day, hour)
        loan = create(:expired_loan, loan_date: loan_date, item_id: item.id, patron_identifier: user.borrower_id)
        (loans_by_date[local_date] ||= []) << loan
      end
    end

    after do
      ENV['TZ'] = env_tz_actual
      Time.zone = rails_tz_actual
    end

    it 'returns loans for the correct date regardless of the Ruby time zone' do
      %w[UTC America/Los_Angeles].each do |tz|
        ENV['TZ'] = tz

        aggregate_failures "loaned_on [TZ = #{tz}]" do
          loans_by_date.each do |local_date, expected_loans|
            actual = Loan.loaned_on(local_date).map(&:loan_date)
            expected = expected_loans.map(&:loan_date)
            expect(actual).to match_array(expected)
          end
        end
      end
    end
  end
end
