require 'calnet_helper'

describe HomeController, type: :request do
  describe :health do
    it 'returns OK for a successful patron lookup' do
      patron = Patron::Record.new
      expect(Patron::Record).to receive(:find).with(Health::Check::TEST_PATRON_ID).and_return(patron)
      get health_path
      expect(response).to have_http_status(:ok)
      expected_body = {
        'status' => 'pass',
        'details' => {
          'patron_api:find' => {
            'status' => 'pass'
          }
        }
      }
      expect(JSON.parse(response.body)).to eq(expected_body)
    end

    it 'returns 429 Too Many Requests for a failure' do
      expect(Patron::Record).to receive(:find).and_raise('Something went wrong')
      get health_path
      expect(response).to have_http_status(:too_many_requests)
      expected_body = {
        'status' => 'warn',
        'details' => {
          'patron_api:find' => {
            'status' => 'warn',
            'output' => 'RuntimeError'
          }
        }
      }
      expect(JSON.parse(response.body)).to eq(expected_body)
    end
  end

  describe :admin do
    it 'allows a framework admin' do
      with_patron_login(Patron::FRAMEWORK_ADMIN_ID) do
        get admin_path
        expect(response).to have_http_status(:ok)
      end
    end

    it 'disallows a non-framework admin' do
      patron_id = Patron::Type.sample_id_for(Patron::Type::VISITING_SCHOLAR)
      with_patron_login(patron_id) do |user|
        expect(user.framework_admin?).to be_falsey # just to be sure

        get admin_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
