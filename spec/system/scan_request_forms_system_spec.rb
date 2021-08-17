require 'capybara_helper'
require 'calnet_helper'

describe :scan_request_forms, type: :system do
  describe 'with a valid user' do
    attr_reader :patron_id
    attr_reader :patron
    attr_reader :user

    before(:each) do
      @patron_id = Patron::Type.sample_id_for(Patron::Type::FACULTY)
      @user = login_as_patron(patron_id)

      @patron = Patron::Record.find(patron_id)
      visit new_scan_request_form_path
    end

    after(:each) do
      logout!
    end

    it 'links to the prntscan email address' do
      support_email = page.find(:xpath, "//a[@class='support-email']")
      expect(support_email['href']).to eq('mailto:prntscan@lists.berkeley.edu')
    end

    it 'defaults to opt-in' do
      opt_in_button = find(:xpath, "//input[@id='scan_request_form_opt_in_true']")
      expect(opt_in_button).to be_checked

      opt_out_button = find(:xpath, "//input[@id='scan_request_form_opt_in_false']")
      expect(opt_out_button).not_to be_checked
    end

    it 'accepts opt-in' do
      choose('scan_request_form_opt_in_true')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page.current_path).to eq('/forms/altmedia/optin')
    end

    it 'accepts opt-out' do
      choose('scan_request_form_opt_in_false')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page.current_path).to eq('/forms/altmedia/optout')
    end
  end
end
