require 'capybara_helper'
require 'calnet_helper'

describe :home, type: :system do
  describe :health do
    it 'does something sensible for a general error' do
      expect(Health::Check).to receive(:new).and_raise('Something went wrong')
      visit health_path
      expect(page).to have_content('Internal Server Error')
    end
  end
end
