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

  describe :update_borrower_token do
    attr_reader :user

    before do
      @user = mock_user_without_login(:student)
    end

    it 'updates the token' do
      old_token = user.borrower_token
      new_token = Lending::BorrowerToken.new_token_for(user.uid)
      user.update_borrower_token(new_token.token_str)
      expect(user.borrower_token).to eq(new_token)
      expect(user.borrower_token).not_to eq(old_token)
    end

    it 'ignores invalid tokens' do
      old_token = user.borrower_token
      new_token = Lending::BorrowerToken.new_token_for('some other UID')
      user.update_borrower_token(new_token.token_str)
      expect(user.borrower_token).to be(old_token)
      expect(user.borrower_token).not_to eq(new_token)
    end
  end

  describe :inspect do
    it 'does not include the borrower ID' do
      user = mock_user_without_login(:student)
      expect(user.inspect).not_to include(user.borrower_id)
    end
  end

  describe 'LIT-2700' do
    describe :ucb_student? do
      it 'accepts the user from LIT-2700 as a student' do
        auth_yml = File.read('spec/data/calnet/LIT-2700.json')
        auth_hash = JSON.parse(auth_yml)
        user = User.from_omniauth(auth_hash)
        expect(user.ucb_student?).to eq(true)
      end
    end
  end
end
