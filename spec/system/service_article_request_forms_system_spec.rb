require 'capybara_helper'
require 'calnet_helper'

describe :service_article_request_forms, type: :system do
  describe 'with a valid user' do
    attr_reader :patron_id
    attr_reader :patron
    attr_reader :user

    before(:each) do
      @patron_id = Patron::Type.sample_id_for(Patron::Type::POST_DOC)
      @user = login_as_patron(patron_id)

      @patron = Patron::Record.find(patron_id)
      eligible = patron.notes.any? { |n| n =~ /book scan eligible/ }
      expect(eligible).to eq(true) # just to be sure

      visit new_service_article_request_form_path
    end

    after(:each) do
      logout!
    end

    it 'links to the baker email address' do
      support_email = page.find(:xpath, "//a[@class='support-email']")
      expect(support_email['href']).to eq('mailto:baker@library.berkeley.edu')
    end

    it 'prepopulates the patron email as a required field' do
      expected_email = patron.email
      patron_email_field = find(:xpath, "//input[@id='service_article_request_form_patron_email']")
      expect(patron_email_field['value']).to eq(expected_email)
      expect(patron_email_field['required']).to be_truthy
    end

    it 'marks all required fields as required' do
      required_fields = %w[article_title display_name pub_title vol]
      required_fields.each do |field_name|
        field = find(:xpath, "//input[@id='service_article_request_form_#{field_name}']")
        expect(field['required']).to be_truthy
      end
    end

    it 'accepts a submission' do
      required_fields = %w[article_title display_name pub_title vol]
      required_fields.each do |field_name|
        fill_in("service_article_request_form_#{field_name}", with: "value for #{field_name}")
      end

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page.current_path).to eq('/forms/altmedia-articles/confirmed')
    end
  end

  describe 'with an invalid patron type' do
    it 'throws patron not eligible error' do
      patron_id = Patron::Type.sample_id_for(Patron::Type::UNDERGRAD)
      login_as_patron(patron_id)
      patron = Patron::Record.find(patron_id)
      patron.notes = nil

      visit new_service_article_request_form_path

      expect(page).to have_content('you are not eligible')
    end
  end
end
