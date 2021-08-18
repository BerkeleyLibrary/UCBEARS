require 'rails_helper'

describe User do
  describe :from_omniauth do
    it 'rejects invalid providers' do
      auth = { 'provider' => 'not calnet' }
      expect { User.from_omniauth(auth) }.to raise_error(Error::InvalidAuthProviderError)
    end
  end
end
