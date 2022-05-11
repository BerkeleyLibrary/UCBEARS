require 'rails_helper'

describe ExceptionHandling, type: :system do
  describe Error::UnauthorizedError do
    it 'returns 401 unauthorized for JSON requests' do
      expected_msg = 'Endpoint sessions/index requires authentication'

      raw_get('/', as: :json)
      expect_json_error(:unauthorized, expected_msg)
    end

    it 'redirects to login for HTML requests' do
      expected_location = "#{ensure_uri(login_path)}?#{URI.encode_www_form(url: '/')}"

      raw_get('/', as: :html)
      expect(response).to redirect_to(expected_location)
      expect(response.content_type).to start_with('text/html')
    end

    it 'redirects to login for CSV requests' do
      expected_location = "#{ensure_uri(login_path)}?#{URI.encode_www_form(url: '/')}"

      raw_get '/', as: :csv
      expect(response).to redirect_to(expected_location)
      expect(response.content_type).to start_with('text/html')
    end
  end

  describe ActiveRecord::RecordNotFound do
    let(:bad_id) { 'not_an_item' }

    before do
      user = instance_double(User)
      allow(user).to receive(:authenticated?).and_return(true)
      allow(user).to receive(:uid).and_return('12345')
      allow(user).to receive(:ucb_student?).and_return(true)
      %i[ucb_staff? ucb_faculty? lending_admin?].each do |m|
        allow(user).to receive(m).and_return(false)
      end

      allow(User).to receive(:from_session).and_return(user)
    end

    it 'returns 404 not found for JSON requests' do
      expected_msg = "Couldn't find Item with 'id'=#{bad_id}"

      raw_get item_url(id: bad_id), as: :json
      expect_json_error(:not_found, expected_msg)
    end

    it 'returns 404 not found for HTML requests' do
      bad_url = lending_view_url(directory: bad_id)
      raw_get bad_url, as: :html
      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to start_with('text/html')
    end
  end

end
