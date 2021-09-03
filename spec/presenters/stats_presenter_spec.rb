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

    describe :all_session_stats do
      it 'counts by combination of user types' do
        expected_counts_by_type = users.each_with_object({}) do |user, counts|
          types = %i[student staff faculty admin].select do |type|
            flag_accessor = flag_accessors_by_type[type]
            user.send(flag_accessor)
          end.map(&:to_s).sort
          counts_for_types = (counts[types] ||= { total_sessions: 0, unique_users: 0 })
          counts_for_types[:total_sessions] += expected_counts_by_user[user]
          counts_for_types[:unique_users] += 1
        end

        expected_stats = expected_counts_by_type.map do |types, counts|
          SessionStats.new(types, counts[:total_sessions], counts[:unique_users])
        end.sort

        actual_stats = sp.all_session_stats
        expect(actual_stats).to eq(expected_stats)
      end
    end
  end

  describe 'loan and item stats' do
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

    context 'loan stats' do

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
          expect(sp.loan_duration_median).to be_within(0.5).of(expected)
        end
      end
    end

    context 'item stats' do
      describe :item_lending_stats_by_date do
        it 'returns the loans for the correct date' do
          sp.item_lending_stats_by_date.each do |date, stats_for_date|
            stats_for_date.each do |item_stats|
              item_stats.loans.map(&:loan_date).each do |loan_date|
                expect(loan_date.to_date).to eq(date)
              end
            end
          end
        end

        it 'returns the correct loans for each item' do
          sp.item_lending_stats_by_date.each do |_, stats_for_date|
            stats_for_date.each do |item_stats|
              item = item_stats.item
              item_stats.loans.each do |loan|
                expect(loan.lending_item).to eq(item)
              end
            end
          end
        end

        it 'returns the expected counts' do
          counts_by_state_by_item_id = {}
          sp.item_lending_stats_by_date.each do |_, all_stats_for_date|
            all_stats_for_date.each do |stats|
              item_id = stats.item.id
              counts_by_state = (counts_by_state_by_item_id[item_id] ||= {})
              stats.loan_counts_by_state.each do |state, count|
                counts_by_state[state] = counts_by_state.fetch(state, 0) + count
              end
            end
          end

          counts_by_state_by_item_id.each do |item_id, counts_by_state|
            counts_by_state.each do |state, count|
              expected_count = LendingItemLoan.where(lending_item_id: item_id, loan_status: state).count
              expect(count).to eq(expected_count)
            end
          end
        end
      end
    end
  end
end
