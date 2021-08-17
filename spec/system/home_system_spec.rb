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

  describe :admin do
    it 'allows a framework admin' do
      with_patron_login(Patron::FRAMEWORK_ADMIN_ID) do
        visit admin_path
        expect(page).to have_content('UC Berkeley Library Forms')
      end
    end

    it 'disallows a non-framework admin' do
      patron_id = Patron::Type.sample_id_for(Patron::Type::VISITING_SCHOLAR)
      with_patron_login(patron_id) do |user|
        expect(user.framework_admin?).to be_falsey # just to be sure

        visit admin_path
        expect(page).to have_content('Only Library IT developers can access this page.')
      end
    end
  end
end
