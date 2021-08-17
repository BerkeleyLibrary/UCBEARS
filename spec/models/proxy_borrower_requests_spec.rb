require 'rails_helper'
require 'time'

describe ProxyBorrowerRequests do
  before(:all) do
    # Calculate and define the max date and an invalid date:
    today = Date.current
    mo = today.month
    yr = today.year
    yr += 1 if mo >= 4
    @max_date = Date.new(yr, 6, 30)

    # Thou shalt pass paramters as strings:
    @invalid_date_str = Date.new(yr, 7, 1).to_s(:long)
    @max_date_err_str = @max_date.to_s(:long)
  end

  it 'validates the form' do
    tests = [
      {
        valid: false,
        attributes: {},
        errors: {
          research_last: ['Last name of proxy must not be blank.'],
          research_first: ['First name of proxy must not be blank.'],
          date_term: ['Term of proxy card must not be blank and must be in the format mm/dd/yyyy.']
        }
      },
      {
        valid: false,
        attributes: {
          date_term: Date.new(2000, 6, 30)
        },
        errors: {
          date_term: ['The Proxy Term must not be in the past.']
        }
      },
      {
        valid: false,
        attributes: {
          date_term: Date.current.next_day(720)
        },
        errors: {
          date_term: ["The term of the Proxy Card must not be greater than #{@max_date_err_str}."]
        }
      },
      {
        valid: true,
        attributes: {
          research_last: 'Doe',
          research_first: 'Jane',
          date_term: Date.current.next_day(0)
        },
        errors: {
          research_last: [],
          research_first: [],
          date_term: []
        }
      }
    ]
    tests.each do |attributes:, errors:, valid:|
      form = ProxyBorrowerRequests.new(attributes)
      expect(form.valid?).to eq(valid)
      next if valid

      errors.each do |attr_name, attr_errs|
        expect(form.errors[attr_name]).to eq(attr_errs)
      end
    end
  end

  it 'returns a full name' do
    attributes = {
      research_last: 'Doe',
      research_first: 'Jane',
      date_term: Date.current.next_day(0)
    }

    form = ProxyBorrowerRequests.new(attributes)
    expect(form.full_name).to eq('Doe, Jane')
  end

  it 'CSV export returns expected columns' do
    # Looks like in Jenkinsland I need to create a record
    attributes = {
      research_last: 'CSVLast',
      research_first: 'CSVFirst',
      date_term: @max_date
    }

    # Create a new request
    new_request = ProxyBorrowerRequests.new(attributes)

    # Save it
    new_request.save

    # Then grab it
    requests = ProxyBorrowerRequests.all

    # Now we should have a record to conver to csv
    csv = requests.to_csv
    expect(csv).to start_with 'faculty_name,department,student_name,dsp_rep,proxy_name,user_email,date_term,date_requested'

  end
end
