require 'rails_helper'

RSpec.describe '/terms', type: :request do
  def expected_json(term)
    renderer = ApplicationController.renderer.new(http_host: request.host)
    expected_json = renderer.render(template: 'terms/show', assigns: { term: term })
    JSON.parse(expected_json)
  end

  let(:valid_attributes) do
    {
      name: 'Fall 2019',
      start_date: Date.new(2019, 7, 21),
      end_date: Date.new(2019, 12, 20)
    }
  end

  let(:invalid_attributes) do
    {
      name: 'Fall 1999',
      start_date: Date.new(1999, 12, 31),
      end_date: Date.new(1999, 1, 1)
    }
  end

  before do
    {
      lending_root_path: Pathname.new('spec/data/lending'), iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end

    %i[term_fall_2021 term_spring_2022].each { |t| create(t) }
  end

  context 'without credentials' do
    describe 'GET /index' do
      it 'redirects HTML requests to login' do
        get terms_url, as: :html
        expected_location = "#{login_path}?#{URI.encode_www_form(url: terms_path)}"
        expect(response).to redirect_to(expected_location)
      end

      it 'returns 401 Unauthorized for JSON requests' do
        expected_status = 401
        expected_message = 'Endpoint terms/index requires authentication'

        get terms_url, as: :json
        expect_json_error(expected_status, expected_message)
      end
    end
  end

  context 'with patron credentials' do
    before { mock_login(:student) }

    after { logout! }

    describe 'GET /index' do
      it 'returns 403 Forbidden for HTML requests' do
        get terms_url, as: :html
        expect(response.status).to eq(403)
        expect(response.content_type).to start_with('text/html')
        expect(response.body).to include('restricted to UC BEARS administrators')
      end

      it 'returns the terms for JSON requests' do
        get terms_url, as: :json

        expect(response).to be_successful
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_an(Array)

        expected_terms = Term.all
        expect(parsed_response.size).to eq(expected_terms.size)

        expected_terms.each_with_index do |term, i|
          expect(parsed_response[i]).to eq(expected_json(term))
        end
      end
    end
  end

  context 'with lending admin credentials' do
    before { mock_login(:lending_admin) }

    after { logout! }

    describe :index do
      it 'returns all terms' do
        get terms_url, as: :json

        expect(response).to be_successful
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_an(Array)

        expected_terms = Term.all
        expect(parsed_response.size).to eq(expected_terms.size)

        expected_terms.each_with_index do |term, i|
          expect(parsed_response[i]).to eq(expected_json(term))
        end
      end
    end

    describe :show do
      it 'return the term' do
        term = Term.take

        get term_url(term), as: :json
        expect(response).to be_successful
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to eq(expected_json(term))
      end
    end

    describe :create do
      it 'creates a term' do
        expect do
          post terms_url, params: { term: valid_attributes }, as: :json
        end.to change(Term, :count).by(1)

        term = Term.find_by(name: valid_attributes[:name])
        valid_attributes.each { |attr, value| expect(term.send(attr)).to eq(value) }
      end

      it 'returns the term as JSON' do
        post terms_url, params: { term: valid_attributes }, as: :json
        expect(response).to be_successful
        expect(response.content_type).to match(%r{^application/json})

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_a(Hash)

        expected = {
          'name' => valid_attributes[:name],
          'start_date' => valid_attributes[:start_date].in_time_zone.iso8601,
          'end_date' => valid_attributes[:end_date].in_time_zone.iso8601
        }

        aggregate_failures do
          expected.each do |k, v_expected|
            expect(parsed_response).to have_key(k)
            expect(parsed_response[k]).to eq(v_expected)
          end
        end
      end

      it 'returns a JSON response for an empty term' do
        expect do
          post terms_url, params: { term: {} }, as: :json
        end.not_to change(Term, :count)

        expect(response.content_type).to match(%r{^application/json})
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns errors for an invalid term' do
        expect do
          post terms_url, params: { term: invalid_attributes }, as: :json
        end.not_to change(Term, :count)

        expect(Term.where(name: invalid_attributes[:name])).not_to exist

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_a(Hash)

        expect(parsed_response['success']).to eq(false)

        parsed_error = parsed_response['error']
        expect(parsed_error).to be_a(Hash)
        expect(parsed_error['code']).to eq(422)

        errors = parsed_error['errors']
        messages = errors.map { |err| err['message'] }
        expect(messages.size).to eq(1)
        expect(messages.first).to eq(Term::MSG_START_MUST_PRECEDE_END)
      end

      it 'returns errors for a duplicate term name' do
        term = Term.create(valid_attributes)

        new_attributes = {
          name: term.name,
          start_date: term.start_date - 1.week,
          end_date: term.end_date + 1.week
        }

        expect do
          post terms_url, params: { term: new_attributes }, as: :json
        end.not_to change(Term, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(%r{^application/json})

        expected_msg = I18n.t('activerecord.errors.messages.taken')
        expected_msg_re = /#{Regexp.escape(expected_msg)}/

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_a(Hash)

        expect(parsed_response['success']).to eq(false)

        parsed_error = parsed_response['error']
        expect(parsed_error).to be_a(Hash)
        expect(parsed_error['code']).to eq(422)

        errors = parsed_error['errors']
        messages = errors.map { |err| err['message'] }
        expect(messages.size).to eq(1)
        expect(messages.first).to match(expected_msg_re)
      end
    end

    describe :update do
      it 'updates a term' do
        term = Term.create(valid_attributes)

        new_attributes = {
          name: "#{term.name} (new and improved!)",
          start_date: term.start_date - 1.week,
          end_date: term.end_date + 1.week
        }

        patch term_url(term), params: { term: new_attributes }, as: :json

        term.reload
        expect(term.name).to eq(new_attributes[:name])
        expect(term.start_date).to eq(new_attributes[:start_date])
        expect(term.end_date).to eq(new_attributes[:end_date])

        expect(response).to be_successful
        expect(response.content_type).to match(%r{^application/json})

        actual_json = JSON.parse(response.body)
        expect(actual_json).to eq(expected_json(term))
      end

      it 'applies a partial update' do
        term = Term.create(valid_attributes)

        new_start_date = term.start_date - 1.week
        new_attributes = { start_date: new_start_date }

        patch term_url(term), params: { term: new_attributes }, as: :json

        term.reload
        expect(term.start_date).to eq(new_start_date)

        expect(response).to be_successful
        expect(response.content_type).to match(%r{^application/json})

        actual_json = JSON.parse(response.body)
        expect(actual_json).to eq(expected_json(term))
      end

      it 'does not apply an invalid update' do
        term = Term.create(valid_attributes)
        prev_updated_at = term.updated_at

        patch term_url(term), params: { term: invalid_attributes }, as: :json

        term.reload
        expect(term.updated_at).to eq(prev_updated_at)
        valid_attributes.each { |attr, value| expect(term.send(attr)).to eq(value) }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_a(Hash)

        expect(parsed_response['success']).to eq(false)

        parsed_error = parsed_response['error']
        expect(parsed_error).to be_a(Hash)
        expect(parsed_error['code']).to eq(422)

        errors = parsed_error['errors']
        messages = errors.map { |err| err['message'] }
        expect(messages.size).to eq(1)
        expect(messages.first).to eq(Term::MSG_START_MUST_PRECEDE_END)
      end

      it 'does not accept duplicate names' do
        terms = Term.all
        expect(terms.size).to be > 1 # just to be sure

        term = terms.first
        prev_name = term.name
        prev_updated_at = term.updated_at

        other_term = terms.last
        prev_other_updated_at = other_term.updated_at

        patch term_url(term), params: { term: { name: other_term.name } }, as: :json

        term.reload
        expect(term.updated_at).to eq(prev_updated_at)
        expect(term.name).to eq(prev_name)

        other_term.reload
        expect(other_term.updated_at).to eq(prev_other_updated_at)

        expected_msg = I18n.t('activerecord.errors.messages.taken')
        expected_msg_re = /#{Regexp.escape(expected_msg)}/

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_a(Hash)

        expect(parsed_response['success']).to eq(false)

        parsed_error = parsed_response['error']
        expect(parsed_error).to be_a(Hash)
        expect(parsed_error['code']).to eq(422)

        errors = parsed_error['errors']
        messages = errors.map { |err| err['message'] }
        expect(messages.size).to eq(1)
        expect(messages.first).to match(expected_msg_re)
      end
    end

    describe :destroy do
      it 'deletes a term' do
        term = Term.take

        expect do
          delete term_url(term), as: :json
        end.to change(Term, :count).by(-1)

        expect(response).to be_successful
      end

      # TODO: Should this be a 404?
      it 'succeeds if the term has already been deleted' do
        term = Term.take
        term.destroy!

        expect do
          delete term_url(term), as: :json
        end.not_to change(Term, :count)

        expect(response).to be_successful
      end
    end
  end
end
