require 'capybara_helper'
require 'time'

describe :reference_card_form, type: :system do
  context 'request specs' do
    it 'marks all required fields as required' do
      visit new_reference_card_form_path

      required_fields = %w[
        reference_card_form_name
        reference_card_form_email
        reference_card_form_pass_date
        reference_card_form_local_id
      ]
      required_fields.each do |field_name|
        field = find(:xpath, "//input[@id='#{field_name}']")
        expect(field['required']).to be_truthy
      end
    end

    it 'accepts a valid request' do
      visit new_reference_card_form_path
      fill_in('reference_card_form_name', with: 'John Doe')
      fill_in('reference_card_form_affiliation', with: 'Red Bull')
      fill_in('reference_card_form_email', with: 'jdoe@library.edu')
      fill_in('reference_card_form_research_desc', with: 'History of Formula 1')
      fill_in('reference_card_form_pass_date', with: "04/13/25\t") # \t to tab off date field
      fill_in('reference_card_form_pass_date_end', with: "04/14/25\t") # \t to tab off date field
      fill_in('reference_card_form_local_id', with: '123456789')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content('Your request for a Reference Card has been submitted')
    end

    it 'fails a request with an incorrectly formatted date' do
      visit new_reference_card_form_path
      fill_in('reference_card_form_name', with: 'John Doe')
      fill_in('reference_card_form_affiliation', with: 'Red Bull')
      fill_in('reference_card_form_email', with: 'jdoe@library.edu')
      fill_in('reference_card_form_research_desc', with: 'History of Formula 1')
      fill_in('reference_card_form_pass_date', with: "04---13---1996\t") # \t to tab off date field
      fill_in('reference_card_form_pass_date_end', with: "04/14/2025\t") # \t to tab off date field
      fill_in('reference_card_form_local_id', with: '123456789')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content('Requested access start date must not be blank and must be in the format mm/dd/yyyy')
    end

    it 'fails a request with an bad date' do
      visit new_reference_card_form_path
      fill_in('reference_card_form_name', with: 'John Doe')
      fill_in('reference_card_form_affiliation', with: 'Red Bull')
      fill_in('reference_card_form_email', with: 'jdoe@library.edu')
      fill_in('reference_card_form_research_desc', with: 'History of Formula 1')
      fill_in('reference_card_form_pass_date', with: "00/00/0000\t") # \t to tab off date field
      fill_in('reference_card_form_pass_date_end', with: "9999999\t") # \t to tab off date field
      fill_in('reference_card_form_local_id', with: '123456789')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content('Requested access start date must not be blank and must be in the format mm/dd/yyyy')
    end

    it 'fails a request with a bad email address' do
      visit new_reference_card_form_path
      fill_in('reference_card_form_name', with: 'John Doe')
      fill_in('reference_card_form_affiliation', with: 'Red Bull')
      fill_in('reference_card_form_email', with: 'NOT-AN-EMAIL-ADDRESS')
      fill_in('reference_card_form_research_desc', with: 'History of Formula 1')
      fill_in('reference_card_form_pass_date', with: "04/13/1996\t") # \t to tab off date field
      fill_in('reference_card_form_pass_date_end', with: "04/14/1996\t") # \t to tab off date field
      fill_in('reference_card_form_local_id', with: '123456789')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content('is not a valid email address')
    end
  end

  context 'approve/deny specs' do

    before(:each) do
      # Create some requests:
      form = ReferenceCardForm.create(email: 'openreq@test.com', name: 'John Doe',
                                      affiliation: 'Red Bull', pass_date: Date.current, pass_date_end: 1.day.from_now, local_id: '8675309')

      # These functions require admin privledges:
      admin_user = User.new(display_name: 'Test Admin', uid: '1707532', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(ReferenceCardFormsController).to receive(:current_user).and_return(admin_user)

      visit "/forms/reference-card/#{form.id}"
    end

    it 'allows an admin to deny a request' do
      # Fill in the fields:
      choose('stack_pass_deny')
      select('3-month maximum exceeded', from: 'stack_pass_denial_denial_reason', visible: :all)
      fill_in('processed_by', with: 'ADMIN USER')

      # Submit:
      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      # Verify Results:
      expect(page).to have_content('This request has been processed')
    end

    it 'allows an admin to approve a request' do
      # Fill in the fields:
      choose('stack_pass_approve')
      fill_in('processed_by', with: 'ADMIN USER')

      # Submit:
      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      # Verify Results:
      expect(page).to have_content('This request has been processed')
    end
  end

end
