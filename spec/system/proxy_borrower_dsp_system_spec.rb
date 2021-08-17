require 'capybara_helper'
require 'calnet_helper'
require 'capybara_helper'
require 'time'

describe :forms_proxy_borrower_dsp, type: :system do
  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  before(:all) do
    # Calculate and define the max date and an invalid date:
    today = Date.current
    mo = today.month
    yr = today.year
    yr += 1 if mo >= 4
    max_date = Date.new(yr, 6, 30)
    invalid_date = Date.new(yr, 7, 1)

    # Thou shalt pass paramters as strings:
    @invalid_date_str = invalid_date.to_s(:input)
    @max_date_str = max_date.to_s(:input)
  end

  before(:each) do
    @patron_id = Patron::Type.sample_id_for(Patron::Type::UNDERGRAD_SLE)
    @user = login_as_patron(patron_id)
    @patron = Patron::Record.find(patron_id)

    visit forms_proxy_borrower_dsp_path
  end

  after(:each) do
    logout!
  end

  it 'marks all required fields as required' do
    required_fields = %w[
      research_last
      research_first
      term
      dsp_rep
    ]

    # Check required text fields:
    required_fields.each do |field_name|
      field = find(:xpath, "//input[@id='#{field_name}']")
      expect(field['required']).to be_truthy
    end

  end

  it 'rejects a request with missing required data' do
    # TODO: instead of using spaces to get around the JavaScript empty check, test
    #       the JavaScript, then test the server-side validation in a request spec
    fill_in('student_name', with: ' ')
    fill_in('research_last', with: ' ')
    fill_in('research_first', with: ' ')
    fill_in('dsp_rep', with: ' ') # TODO: add server-side validation for this (currently only JS)
    fill_in('term', with: "#{@max_date_str}\t") # \t to tab off date field

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page).to have_content('Last name of proxy must not be blank')
    expect(page).to have_content('First name of proxy must not be blank')
  end

  it 'rejects a request with a non-date term' do
    fill_in('student_name', with: 'Luke Skywalker')
    fill_in('research_last', with: 'Doe')
    fill_in('research_first', with: 'John')
    fill_in('dsp_rep', with: 'Jane Roe')

    fill_in('term', with: "33333333\t") # \t to tab off date field

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page).to have_content('Term of proxy card must not be blank and must be in the format mm/dd/yyyy')
  end

  it 'rejects a request with an invalid date term' do
    fill_in('student_name', with: 'Luke Skywalker')
    fill_in('research_last', with: 'Doe')
    fill_in('research_first', with: 'John')
    fill_in('dsp_rep', with: 'Jane Roe')

    fill_in('term', with: "#{@invalid_date_str}\t") # \t to tab off date field

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    today = Date.current
    year = today.month >= 4 ? today.year + 1 : today.year
    expected_max = Date.new(year, 6, 30).to_s(:long)

    expect(page).to have_content("The term of the Proxy Card must not be greater than #{expected_max}.")
  end

  it 'accepts a valid request' do
    fill_in('student_name', with: 'Luke Skywalker')
    fill_in('research_last', with: 'Doe')
    fill_in('research_first', with: 'John')
    fill_in('dsp_rep', with: 'Jane Roe')
    fill_in('term', with: "#{@max_date_str}\t") # \t to tab off date field

    submit_button = find(:xpath, "//input[@type='submit']")
    submit_button.click

    expect(page.current_path).to eq(forms_proxy_borrower_request_dsp_path)
    expect(page).to have_content('The form has been submitted')
  end

end
