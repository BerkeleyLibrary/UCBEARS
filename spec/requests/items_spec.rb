require 'rails_helper'

RSpec.describe '/items', type: :request do
  let(:valid_headers) { {} }
  let(:valid_attributes) { attributes_for(:inactive_item) }
  let(:invalid_attributes) do
    valid_attributes.merge({ directory: 'Not a valid item directory' })
  end

  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

  describe 'GET /index' do
    it 'returns a JSON response' do
      Item.create! valid_attributes
      get items_url, headers: valid_headers, as: :json
      expect(response).to be_successful
      expect(response.content_type).to match(%r{^application/json})

      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_an(Array)
      expect(parsed_response.size).to eq(1)

      item = Item.find_by!(directory: valid_attributes[:directory])
      expected_json = item.as_json

      actual_json = parsed_response[0]
      expect(actual_json).to include(**expected_json)
    end

    # it 'returns an HTML response' do
    #   get items_url, headers: valid_headers
    #   expect(response).to be_successful
    #   expect(response.content_type).to match(%r{^text/html})
    # end
  end

  describe 'GET /show' do
    it 'renders a successful response' do
      item = Item.create! valid_attributes
      get item_url(item), as: :json
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new Item' do
        expect do
          post items_url,
               params: { item: valid_attributes }, headers: valid_headers, as: :json
        end.to change(Item, :count).by(1)

        item = Item.find_by!(directory: valid_attributes[:directory])
        valid_attributes.each { |attr, value| expect(item.send(attr)).to eq(value) }
      end

      it 'renders a JSON response with the new item' do
        post items_url,
             params: { item: valid_attributes }, headers: valid_headers, as: :json

        item = Item.find_by!(directory: valid_attributes[:directory])
        expected_json = item.as_json

        actual_json = JSON.parse(response.body)
        expect(actual_json).to include(**expected_json)

        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(%r{^application/json})
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Item' do
        expect do
          post items_url,
               params: { item: invalid_attributes }, as: :json
        end.to change(Item, :count).by(0)
      end

      it 'renders a JSON response with errors for the new item' do
        post items_url,
             params: { item: invalid_attributes }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(%r{^application/json})
      end
    end
  end

  describe 'PATCH /update' do
    context 'with valid parameters' do
      let(:new_attributes) do
        valid_attributes.merge({ active: true, copies: 3 })
      end

      it 'updates the requested item' do
        item = Item.create! valid_attributes
        patch item_url(item), params: { item: new_attributes }, headers: valid_headers, as: :json

        item.reload
        new_attributes.each { |attr, value| expect(item.send(attr)).to eq(value) }
      end

      it 'renders a JSON response with the item' do
        item = Item.create! valid_attributes
        patch item_url(item), params: { item: new_attributes }, headers: valid_headers, as: :json

        item.reload
        expected_json = item.as_json

        actual_json = JSON.parse(response.body)
        expect(actual_json).to include(**expected_json)

        expect(response.content_type).to match(%r{^application/json})
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid parameters' do
      it 'renders a JSON response with errors for the item' do
        item = Item.create! valid_attributes
        patch item_url(item),
              params: { item: invalid_attributes }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(%r{^application/json})
      end
    end
  end

  describe 'DELETE /destroy' do
    it 'destroys the requested item' do
      item = Item.create! valid_attributes
      expect do
        delete item_url(item), headers: valid_headers, as: :json
      end.to change(Item, :count).by(-1)
    end
  end
end
