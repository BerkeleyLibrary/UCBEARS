require 'rails_helper'

describe User do
  describe :from_omniauth do
    it 'rejects invalid providers' do
      auth = { 'provider' => 'not calnet' }
      expect { User.from_omniauth(auth) }.to raise_error(Error::InvalidAuthProviderError)
    end
  end

  describe :borrower_id do
    it 'returns a borrower ID' do
      user = mock_user_without_login(:student)
      expect(user.borrower_id).not_to be_nil
    end

    it 'returns different borrower IDs for the same UID' do
      users = Array.new(3) { mock_user_without_login(:student) }

      unique_uids = users.map(&:uid).uniq
      expect(unique_uids.size).to eq(1) # just to be sure

      unique_borrower_ids = users.map(&:borrower_id).uniq
      expect(unique_borrower_ids.size).to eq(users.size)
    end

    it 'returns different borrower IDs for different UIDs' do
      types = %i[student faculty staff]
      users = types.map { |t| mock_user_without_login(t) }

      unique_uids = users.map(&:uid).uniq
      expect(unique_uids.size).to eq(types.size) # just to be sure

      unique_borrower_ids = users.map(&:borrower_id).uniq
      expect(unique_borrower_ids.size).to eq(types.size)
    end
  end
end
