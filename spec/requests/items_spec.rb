require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to test the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator. If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails. There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.

RSpec.describe '/items', type: :request do
  # This should return the minimal set of attributes required to create a valid
  # Item. As you add validations to Item, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    attributes_for(:inactive_item)
  end

  let(:invalid_attributes) do
    valid_attributes.merge({ directory: 'Not a valid item directory' })
  end

  # This should return the minimal set of values that should be in the headers
  # in order to pass any filters (e.g. authentication) defined in
  # ItemsController, or in your router and rack
  # middleware. Be sure to keep this updated too.
  let(:valid_headers) do
    {}
  end

  describe 'GET /index' do
    it 'renders a successful response' do
      Item.create! valid_attributes
      get items_url, headers: valid_headers, as: :json
      expect(response).to be_successful
    end
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
