require 'rails_helper'

RSpec.describe '/items', type: :request do

  def expected_json(item)
    bind = binding.tap { |b| b.local_variable_set(:item, item) }
    template_result('app/views/items/_item.json.jbuilder', bind)
  end

  let(:valid_attributes) { attributes_for(:inactive_item) }
  let(:invalid_attributes) do
    valid_attributes.merge({ directory: 'Not a valid item directory' })
  end

  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'), iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

  describe 'GET /index' do
    let(:factory_names) do
      %i[
        complete_item
        active_item
        incomplete_no_directory
        incomplete_no_images
        incomplete_no_marc
        incomplete_no_manifest
        incomplete_marc_only
      ]
    end

    attr_reader :items

    before(:each) do
      # NOTE: we're deliberately not validating here, because we want some invalid items
      @items = factory_names.each_with_object({}) do |fn, items|
        items[fn] = build(fn).tap { |it| it.save!(validate: false) }
      end
    end

    it 'returns all items by default' do
      get items_url, as: :json
      expect(response).to be_successful
      expect(response.content_type).to match(%r{^application/json})

      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_an(Array)

      expected_items = Item.order(:title)
      expect(parsed_response.size).to eq(expected_items.size)

      # noinspection RubyUnusedLocalVariable
      expected_items.each_with_index do |item, i|
        expected_json = template_result('app/views/items/_item.json.jbuilder', binding)
        expect(parsed_response[i]).to eq(expected_json)
      end
    end

    it 'can exclude incomplete items' do
      get items_url, params: { query: { complete: true } }, as: :json
      expect(response).to be_successful
      expect(response.content_type).to match(%r{^application/json})

      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_an(Array)

      expected_items = Item.all.reject(&:incomplete?)
      expect(expected_items.any?).to eq(true) # just to be sure
      expect(parsed_response.size).to eq(expected_items.size)

      # noinspection RubyUnusedLocalVariable
      expected_items.each_with_index do |item, i|
        expect(parsed_response[i]).to eq(expected_json(item))
      end
    end

    it 'can exclude complete items' do
      get items_url, params: { query: { complete: false } }, as: :json
      expect(response).to be_successful
      expect(response.content_type).to match(%r{^application/json})

      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_an(Array)

      expected_items = Item.all.select(&:incomplete?)
      expect(expected_items.any?).to eq(true) # just to be sure
      expect(parsed_response.size).to eq(expected_items.size)

      # noinspection RubyUnusedLocalVariable
      expected_items.each_with_index do |item, i|
        expect(parsed_response[i]).to eq(expected_json(item))
      end
    end

    it 'can exclude inactive items' do
      get items_url, params: { query: { active: true } }, as: :json
      expect(response).to be_successful
      expect(response.content_type).to match(%r{^application/json})

      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_an(Array)

      expected_items = Item.where(active: true)
      expect(expected_items.exists?).to eq(true) # just to be sure
      expect(parsed_response.size).to eq(expected_items.count)

      # noinspection RubyUnusedLocalVariable
      expected_items.each_with_index do |item, i|
        expect(parsed_response[i]).to eq(expected_json(item))
      end
    end

    it 'can exclude inactive items' do
      get items_url, params: { query: { active: false } }, as: :json
      expect(response).to be_successful
      expect(response.content_type).to match(%r{^application/json})

      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_an(Array)

      expected_items = Item.where(active: false)
      expect(expected_items.exists?).to eq(true) # just to be sure
      expect(parsed_response.size).to eq(expected_items.count)

      # noinspection RubyUnusedLocalVariable
      expected_items.each_with_index do |item, i|
        expect(parsed_response[i]).to eq(expected_json(item))
      end
    end

    it 'can filter inactive items by completeness' do
      get items_url, params: { query: { active: false, complete: true } }, as: :json
      expect(response).to be_successful
      expect(response.content_type).to match(%r{^application/json})

      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_an(Array)

      expected_items = Item.where(active: false).select(&:complete?)
      expect(expected_items.any?).to eq(true) # just to be sure
      expect(parsed_response.size).to eq(expected_items.count)

      # noinspection RubyUnusedLocalVariable
      expected_items.each_with_index do |item, i|
        expect(parsed_response[i]).to eq(expected_json(item))
      end
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
          post items_url, params: { item: valid_attributes }, as: :json
        end.to change(Item, :count).by(1)

        item = Item.find_by!(directory: valid_attributes[:directory])
        valid_attributes.each { |attr, value| expect(item.send(attr)).to eq(value) }
      end

      it 'renders a JSON response with the new item' do
        post items_url, params: { item: valid_attributes }, as: :json

        item = Item.find_by!(directory: valid_attributes[:directory])

        actual_json = JSON.parse(response.body)
        expect(actual_json).to eq(expected_json(item))

        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(%r{^application/json})
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Item' do
        expect do
          post items_url, params: { item: invalid_attributes }, as: :json
        end.to change(Item, :count).by(0)
      end

      it 'renders a JSON response with errors for the new item' do
        post items_url, params: { item: invalid_attributes }, as: :json
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
        patch item_url(item), params: { item: new_attributes }, as: :json

        item.reload
        new_attributes.each { |attr, value| expect(item.send(attr)).to eq(value) }
      end

      it 'renders a JSON response with the item' do
        item = Item.create! valid_attributes
        patch item_url(item), params: { item: new_attributes }, as: :json

        item.reload

        actual_json = JSON.parse(response.body)
        expect(actual_json).to eq(expected_json(item))

        expect(response.content_type).to match(%r{^application/json})
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid parameters' do
      it 'renders a JSON response with errors for the item' do
        item = Item.create! valid_attributes
        patch item_url(item), params: { item: invalid_attributes }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(%r{^application/json})
      end
    end
  end

  describe 'DELETE /destroy' do
    it 'destroys the requested item' do
      item = Item.create! valid_attributes
      expect do
        delete item_url(item), as: :json
      end.to change(Item, :count).by(-1)
    end
  end
end
