require 'rails_helper'

describe ExceptionHandling, type: :request do
  describe Error::UnauthorizedError do
    it 'returns 401 unauthorized for JSON requests' do
      expected_msg = 'Endpoint sessions/index requires authentication'

      get '/', as: :json
      expect_json_error(:unauthorized, expected_msg)
    end

    it 'redirects to login for HTML requests' do
      expected_location = "#{login_path}?#{URI.encode_www_form(url: '/')}"

      get '/', as: :html
      expect(response).to redirect_to(expected_location)
      expect(response.content_type).to start_with('text/html')
    end

    it 'redirects to login for CSV requests' do
      expected_location = "#{login_path}?#{URI.encode_www_form(url: '/')}"

      get '/', as: :csv
      expect(response).to redirect_to(expected_location)
      expect(response.content_type).to start_with('text/html')
    end
  end

  describe ActiveRecord::RecordNotFound do
    let(:bad_id) { 'not_an_item' }

    before { mock_login(:student) }

    after { logout! }

    it 'returns 404 not found for JSON requests' do
      expected_msg = "Couldn't find Item with 'id'=#{bad_id}"

      get item_url(id: bad_id), as: :json
      expect_json_error(:not_found, expected_msg)
    end

    it 'returns 404 not found for HTML requests' do
      bad_url = lending_view_url(directory: bad_id)
      get bad_url, as: :html
      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to start_with('text/html')
    end
  end
end
