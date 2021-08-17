require 'capybara_helper'
require 'time'

describe :stack_pass_form, type: :system do
  context 'system specs' do
    it 'marks all required fields as required' do
      visit new_stack_pass_form_path

      required_fields = %w[
        stack_pass_form_name
        stack_pass_form_email
        stack_pass_form_pass_date
        stack_pass_form_local_id
      ]
      required_fields.each do |field_name|
        field = find(:xpath, "//input[@id='#{field_name}']")
        expect(field['required']).to be_truthy
      end
    end

    it 'accepts a valid request' do
      date_str = Date.current.to_s(:input)
      visit new_stack_pass_form_path
      fill_in('stack_pass_form_name', with: 'John Doe')
      fill_in('stack_pass_form_email', with: 'jdoe@library.edu')
      fill_in('stack_pass_form_phone', with: '925-555-9999')
      fill_in('stack_pass_form_pass_date', with: "#{date_str}\t") # \t to tab off date field
      fill_in('stack_pass_form_local_id', with: '123456789')
      choose('stack_pass_form_main_stack_yes')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content('Your request for a Stack Pass has been submitted')
    end

    it 'fails a request with an incorrectly formatted date' do
      visit new_stack_pass_form_path
      fill_in('stack_pass_form_name', with: 'John Doe')
      fill_in('stack_pass_form_email', with: 'jdoe@library.edu')
      fill_in('stack_pass_form_phone', with: '925-555-9999')
      fill_in('stack_pass_form_pass_date', with: "04---13---1996\t") # \t to tab off date field
      fill_in('stack_pass_form_local_id', with: '123456789')
      choose('stack_pass_form_main_stack_yes')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content('The date must not be blank and must be in the format mm/dd/yyyy')
    end

    it 'fails a request with a bad date' do
      visit new_stack_pass_form_path
      fill_in('stack_pass_form_name', with: 'John Doe')
      fill_in('stack_pass_form_email', with: 'jdoe@library.edu')
      fill_in('stack_pass_form_phone', with: '925-555-9999')
      fill_in('stack_pass_form_pass_date', with: "00/00/00zz\t") # \t to tab off date field
      fill_in('stack_pass_form_local_id', with: '123456789')
      choose('stack_pass_form_main_stack_yes')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content('The date must not be blank and must be in the format mm/dd/yyyy')
    end

    it 'fails a request with a bad email address' do
      visit new_stack_pass_form_path
      fill_in('stack_pass_form_name', with: 'John Doe')
      fill_in('stack_pass_form_email', with: 'NOT-AN-EMAIL-ADDRESS')
      fill_in('stack_pass_form_phone', with: '925-555-9999')
      fill_in('stack_pass_form_pass_date', with: "04/13/1996\t") # \t to tab off date field
      fill_in('stack_pass_form_local_id', with: '123456789')
      choose('stack_pass_form_main_stack_yes')

      submit_button = find(:xpath, "//input[@type='submit']")
      submit_button.click

      expect(page).to have_content('is not a valid email address')
    end
  end

  context 'approve/deny specs' do

    before(:each) do
      # Create some requests:
      form = StackPassForm.create(email: 'openreq@test.com', name: 'John Doe',
                                  phone: '925-555-1234', pass_date: Date.current, main_stack: true, local_id: '8675309')

      # These functions require admin privledges:
      admin_user = User.new(display_name: 'Test Admin', uid: '1707532', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(StackPassFormsController).to receive(:current_user).and_return(admin_user)

      visit "/forms/stack-pass/#{form.id}"
    end

    it 'allows an admin to deny a request' do
      # Fill in the fields:
      choose('stack_pass_deny')
      select('Too many passes requested', from: 'stack_pass_denial_denial_reason', visible: :all)
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
