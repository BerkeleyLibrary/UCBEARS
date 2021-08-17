require 'capybara_helper'
require 'calnet_helper'

describe :doemoff_study_room_use_forms, type: :system do
  describe 'with a valid user' do
    attr_reader :patron_id
    attr_reader :patron
    attr_reader :user

    before(:each) do
      @patron_id = Patron::Type.sample_id_for(Patron::Type::UNDERGRAD_SLE)
      @user = login_as_patron(patron_id)

      @patron = Patron::Record.find(patron_id)
      visit new_doemoff_study_room_use_form_path
    end

    after(:each) do
      logout!
    end

    it 'links to the privileges desk email address' do
      support_email = page.find(:xpath, "//a[@class='support-email']")
      expect(support_email['href']).to eq('mailto:privdesk@library.berkeley.edu')
    end

    it 'looks up the patron record' do
      patron_id_field = find(:xpath, "//input[@id='doemoff_study_room_use_form_patron_id']", visible: :all)
      expect(patron_id_field).not_to be_nil
      expect(patron_id_field.value).to eq(patron_id)
    end

    it 'displays the patron email as a read-only field' do
      expected_email = patron.email
      patron_email_field = find(:xpath, "//input[@id='doemoff_study_room_use_form_patron_email']")
      expect(patron_email_field['value']).to eq(expected_email)
      expect(patron_email_field['readonly']).to be_truthy
    end

    it "displays the user's display name as a read-only field" do
      expected_name = user.display_name
      display_name_field = find(:xpath, "//input[@id='doemoff_study_room_use_form_display_name']")
      expect(display_name_field['value']).to eq(expected_name)
      expect(display_name_field['readonly']).to be_truthy
    end

    it 'marks all checks as required' do
      checks = DoemoffStudyRoomUseForm.instance_methods.map(&:to_s).select { |n| n.end_with?('check') }
      checks.each do |check|
        check_field = find(:xpath, "//input[@id='doemoff_study_room_use_form_#{check}']")
        expect(check_field['required']).to be_truthy
      end
    end

    it 'accepts a submission' do
      checks = DoemoffStudyRoomUseForm.instance_methods.map(&:to_s).select { |n| n.end_with?('check') }
      checks.each do |check|
        check_field = find(:xpath, "//input[@id='doemoff_study_room_use_form_#{check}']")
        check_field.set(true)
      end

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page.current_path).to eq('/forms/doemoff-study-room-use/all_checked')
    end
  end
end
