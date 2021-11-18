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
        iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
      }.each do |getter, val|
        allow(Lending::Config).to receive(getter).and_return(val)
      end
    end

    attr_reader :items, :loans, :completed_loans, :expired_loans, :returned_loans

    before(:each) do
      # TODO: share code among stats_presenter_spec, item_lending_stats_spec, stats_request_spec
      copies_per_item = 2 * users.size

      @items = %i[active_item complete_item].map do |f|
        create(f, copies: copies_per_item, active: true)
      end

      @returned_loans = []

      @loans = []
      users.each do |user|
        loans << create(:active_loan, item_id: items[0].id, patron_identifier: user.borrower_id)
        loans << create(:expired_loan, item_id: items[0].id, patron_identifier: user.borrower_id)
        loans << create(:completed_loan, item_id: items[1].id, patron_identifier: user.borrower_id)
      end

      @returned_loans = loans.select(&:return_date)
      expect(returned_loans).not_to be_empty # just to be sure

      @expired_loans = loans.select(&:expired?)
      expect(expired_loans).not_to be_empty # just to be sure

      @completed_loans = loans.select(&:complete?)
      expect(completed_loans).not_to be_empty # just to be sure

      expect(completed_loans).to match_array(returned_loans + expired_loans) # just to be sure
    end

    context 'loan stats' do
      describe :loan_count_total do
        it 'returns the total number of loans made' do
          expect(sp.loan_count_total).to eq(loans.size)
        end
      end

      describe :loan_count_active do
        it 'returns the number of active loans' do
          expect(sp.loan_count_active).to eq(loans.select(&:active?).size)
        end
      end

      describe :loan_count_complete do
        it 'returns the number of completed loans' do
          expect(sp.loan_count_complete).to eq(loans.select(&:complete?).size)
        end
      end

      describe :loan_count_expired do
        it 'returns the number of expired loans' do
          expect(sp.loan_count_expired).to eq(expired_loans.size)
        end
      end

      describe :loan_count_returned do
        it 'returns the number of returned loans' do
          expect(sp.loan_count_returned).to eq(returned_loans.size)
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
                expect(loan.item).to eq(item)
              end
            end
          end
        end

        it 'returns the expected counts' do
          sp.item_lending_stats_by_date.each do |date, all_stats_for_date|
            all_stats_for_date.each do |stats|
              item = stats.item
              stats.loan_counts_by_status.each do |status, count|
                expected_count = item.loans.send(status).loaned_on(date).count
                expect(count).to eq(expected_count)
              end
            end
          end
        end
      end
    end
  end
end
