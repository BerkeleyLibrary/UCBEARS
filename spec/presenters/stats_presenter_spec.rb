require 'rails_helper'

describe StatsPresenter do
  let(:user_types) { %i[staff faculty student lending_admin] }

  let(:flag_accessors_by_type) do
    { staff: :ucb_staff?, faculty: :ucb_faculty?, student: :ucb_student?, admin: :lending_admin? }
  end

  attr_reader :users, :sp

  before(:each) do
    @users = user_types.map { |t| mock_user_without_login(t) }
    @sp = StatsPresenter.new
  end

  context 'session stats' do
    attr_reader :counts, :expected_counts_by_user, :expected_total

    before(:each) do
      @expected_counts_by_user = {}
      @expected_total = 0
      users.each do |user|
        count_for_user = rand(1..3)
        count_for_user.times { SessionCounter.increment_count_for(user) }
        @expected_total += count_for_user
        @expected_counts_by_user[user] = count_for_user
      end
    end

    describe :session_unique_users do
      it 'returns the number of unique users' do
        expect(sp.session_unique_users).to eq(users.size)
      end
    end

    describe :session_count_total do
      it 'returns the total number of sessions' do
        expect(sp.session_count_total).to eq(expected_total)
      end
    end

    describe :session_counts_by_type do
      it 'counts by type' do
        flag_accessors_by_type.each do |t, flag_accessor|
          users_with_flag = users.select { |u| u.send(flag_accessor) }
          expected_count = users_with_flag.inject(0) { |c, u| c + expected_counts_by_user[u] }
          actual_count = sp.session_counts_by_type[t]
          expect(actual_count).to eq(expected_count)
        end
      end
    end
  end

  describe 'loan stats' do
    before(:each) do
      {
        lending_root_path: Pathname.new('spec/data/lending'),
        iiif_base_uri: URI.parse('http://ucbears-iiif/iiif/')
      }.each do |getter, val|
        allow(Lending::Config).to receive(getter).and_return(val)
      end
    end

    attr_reader :items, :loans, :completed_loans, :expired_loans

    before(:each) do
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

    describe :loan_count_total do
      it 'returns the total number of loans made' do
        expect(sp.loan_count_total).to eq(loans.size)
      end
    end

    describe :loan_count_active do
      it 'returns the number of active loans' do
        expect(sp.loan_count_active).to eq(loans.size / 2)
      end
    end

    describe :loan_count_complete do
      it 'returns the number of completed loans' do
        expect(sp.loan_count_complete).to eq(loans.size / 2)
      end
    end

    describe :loan_count_expired do
      it 'returns the number of expired loans' do
        expect(sp.loan_count_expired).to eq(expired_loans.size)
      end
    end

    describe :loan_duration_avg do
      it 'returns the average loan duration' do
        durations = completed_loans.map(&:duration)
        expected_avg = durations.sum / durations.size

        expect(sp.loan_duration_avg).to be_within(0.01).of(expected_avg)
      end
    end

    describe :loan_duration_median do
      it 'returns the median loan duration' do
        loan_durations = completed_loans.map(&:duration)
        sorted = loan_durations.sort
        len = sorted.length
        expected = (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
        expect(sp.loan_duration_median).to eq(expected)
      end
    end
  end
end
