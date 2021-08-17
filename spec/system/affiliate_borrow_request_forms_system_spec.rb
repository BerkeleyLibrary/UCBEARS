require 'capybara_helper'

describe :affiliate_borrow_request_forms, type: :system do
  before(:each) do
    visit new_affiliate_borrow_request_form_path
  end

  it 'links to the privileges desk email address' do
    support_email = page.find(:xpath, "//a[@class='support-email']")
    expect(support_email['href']).to eq('mailto:privdesk@library.berkeley.edu')
  end

  it "doesn't show a login link" do
    expect(page).not_to have_content('Login')
  end

  it 'marks all required fields as required' do
    required_fields = %w[
      department_name
      department_head_name
      department_head_email
      employee_email
      employee_id
      employee_personal_email
      employee_phone
      employee_name
    ]

    required_fields.each do |field_name|
      field = find(:xpath, "//input[@id='affiliate_borrow_request_form_#{field_name}']")
      expect(field['required']).to be_truthy
    end

    textarea = find(:xpath, "//textarea[@id='affiliate_borrow_request_form_employee_address']")
    expect(textarea['required']).to be_truthy
  end

  it 'displays errors for bad fields' do
    # this shouldn't be possible in the UI, but let's be sure
    query_params = {
      affiliate_borrow_request_form: {
        department_head_email: 'jrdoe<at>affiliate.test',
        department_head_name: 'Jane R. Doe',
        department_name: 'Office of the Vice Provost for Test',
        employee_email: 'rjdoe<at>affiliate.test',
        employee_id: '5551212',
        employee_name: 'Rachel J. Doe',
        employee_personal_email: 'rjdoe<at>example.test',
        employee_phone: '555-1212',
        employee_preferred_name: 'RJ Doe',
        employee_address: '123 Sesame St, Oakland CA 94607'
      }
    }

    submission_url = "#{new_affiliate_borrow_request_form_path}?#{query_params.to_query}"
    visit submission_url
    expect(page.current_path).to eq(new_affiliate_borrow_request_form_path)
    expect(page).not_to have_content('Request successfully submitted')
    expect(page).to have_content('not a valid email address')
    query_params[:affiliate_borrow_request_form].each do |field_name, expected_value|
      field = find_field("affiliate_borrow_request_form_#{field_name}")
      expect(field.value).to eq(expected_value)
    end
  end

  it 'accepts a submission' do
    required_email_addresses = %w[department_head_email employee_email employee_personal_email]
    required_email_addresses.each do |email_address|
      fill_in("affiliate_borrow_request_form_#{email_address}", with: "#{email_address}@example.edu")
    end

    required_fields = %w[department_name department_head_name employee_id employee_phone employee_name employee_address]
    required_fields.each do |field_name|
      fill_in("affiliate_borrow_request_form_#{field_name}", with: "value for #{field_name}")
    end

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page.current_path).to eq(new_affiliate_borrow_request_form_path)
    expect(page).to have_content('Request successfully submitted')
  end
end
