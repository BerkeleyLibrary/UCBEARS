require 'rails_helper'

RSpec.describe '/items', type: :request do

  def expected_json(item)
    renderer = ApplicationController.renderer.new(http_host: request.host)
    expected_json = renderer.render(template: 'items/show', assigns: { item: item })
    JSON.parse(expected_json)
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

  context 'with lending admin credentials' do
    before(:each) { mock_login(:lending_admin) }
    after(:each) { logout! }

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

      attr_reader :term_fall_2021
      attr_reader :term_spring_2022

      before(:each) do
        # NOTE: we're deliberately not validating here, because we want some invalid items
        @items = factory_names.each_with_object([]) do |fn, items|
          items << build(fn).tap { |it| it.save!(validate: false) }
        end

        @term_fall_2021 = create(:term_fall_2021)
        @term_spring_2022 = create(:term_spring_2022)

        items.each_with_index do |it, ix|
          expect(it.terms).to be_empty # just to be sure

          term = ix.even? ? term_fall_2021 : term_spring_2022
          it.terms << term
        end
      end

      it 'returns all items by default' do
        get items_url, as: :json
        expect(response).to be_successful
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_an(Array)

        expected_items = Item.order(:title)
        expect(parsed_response.size).to eq(expected_items.size)

        # noinspection RubyUnusedLocalVariable
        expected_items.each_with_index do |item, i|
          expect(parsed_response[i]).to eq(expected_json(item))
        end
      end

      it 'can exclude incomplete items' do
        get items_url, params: { complete: true }, as: :json
        expect(response).to be_successful
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_an(Array)

        expected_items = Item.complete
        expect(expected_items.any?).to eq(true) # just to be sure
        expect(parsed_response.size).to eq(expected_items.size)

        # noinspection RubyUnusedLocalVariable
        expected_items.each_with_index do |item, i|
          expect(parsed_response[i]).to eq(expected_json(item))
        end
      end

      it 'can exclude complete items' do
        get items_url, params: { complete: false }, as: :json
        expect(response).to be_successful
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_an(Array)

        expected_items = Item.incomplete
        expect(expected_items.any?).to eq(true) # just to be sure
        expect(parsed_response.size).to eq(expected_items.size)

        # noinspection RubyUnusedLocalVariable
        expected_items.each_with_index do |item, i|
          expect(parsed_response[i]).to eq(expected_json(item))
        end
      end

      it 'can exclude inactive items' do
        get items_url, params: { active: true }, as: :json
        expect(response).to be_successful
        expect(response.content_type).to start_with('application/json')

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

      it 'can exclude active items' do
        get items_url, params: { active: false }, as: :json
        expect(response).to be_successful
        expect(response.content_type).to start_with('application/json')

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
        get items_url, params: { active: false, complete: true }, as: :json
        expect(response).to be_successful
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_an(Array)

        expected_items = Item.inactive.complete
        expect(expected_items.any?).to eq(true) # just to be sure
        expect(parsed_response.size).to eq(expected_items.count)

        # noinspection RubyUnusedLocalVariable
        expected_items.each_with_index do |item, i|
          expect(parsed_response[i]).to eq(expected_json(item))
        end
      end

      it 'can filter by term' do
        get items_url, params: { active: true, complete: false, terms: ['Not a term', term_fall_2021.name] }, as: :json
        expect(response).to be_successful
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_an(Array)

        expected_items = term_fall_2021.items.incomplete.where(active: true)
        expect(expected_items).not_to be_empty # just to be sure

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
        expect(response.content_type).to start_with('application/json')
      end

      it 'does something sensible for nonexistent objects' do
        item = build(:incomplete_item)
        item.save!(validate: false)
        item.destroy!

        get item_url(item), as: :json
        expect(response).to have_http_status(404)
        expect(response.content_type).to start_with('application/json')
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

          expect(response.content_type).to start_with('application/json')
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with invalid parameters' do
        it 'renders a JSON response with errors for the item' do
          item = Item.create! valid_attributes
          patch item_url(item), params: { item: invalid_attributes }, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to start_with('application/json')
        end
      end
    end

    describe 'DELETE /destroy' do
      it 'deletes an incomplete item' do
        item = build(:incomplete_item)
        item.save!(validate: false)

        expect do
          delete item_url(item), as: :json
        end.to change(Item, :count).by(-1)

        expect(response).to be_successful
      end

      it 'will not delete a complete item' do
        item = create(:complete_item)

        expect do
          delete item_url(item), as: :json
        end.not_to change(Item, :count)

        expect(response).not_to be_successful
        expect(response.content_type).to start_with('application/json')

        response_json = JSON.parse(response.body)
        expect(response_json).to include(Item::MSG_CANNOT_DELETE_COMPLETE_ITEM)
      end

      it 'succeeds if the item has already been deleted' do
        item = build(:incomplete_item)
        item.save!(validate: false)
        item.destroy!

        expect do
          delete item_url(item), as: :json
        end.not_to change(Item, :count)

        expect(response).to be_successful
      end
    end
  end
end
