require 'rails_helper'

RSpec.describe '/items', type: :request do

  def expected_json(item)
    renderer = ApplicationController.renderer.new(http_host: request.host)
    expected_json = renderer.render(template: 'items/show', assigns: { item: item })
    JSON.parse(expected_json)
  end

  let(:valid_attributes) { attributes_for(:inactive_item) }
  let(:invalid_attributes) do
    valid_attributes.merge({ directory: 'Not a valid item directory', copies: -1 })
  end

  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'), iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

  context 'without credentials' do
    before(:each) do
      %i[complete_item active_item].each { |it| create(it) }
    end

    describe 'GET /index' do
      it 'redirects HTML requests to login' do
        get items_url, as: :html
        expected_location = "#{login_path}?#{URI.encode_www_form(url: items_path)}"
        expect(response).to redirect_to(expected_location)
      end

      it 'returns 401 Unauthorized for JSON requests' do
        expected_status = 401
        expected_message = 'Endpoint items/index requires authentication'

        get items_url, as: :json
        expect_json_error(expected_status, expected_message)
      end
    end
  end

  context 'with patron credentials' do
    before(:each) do
      %i[complete_item active_item].each { |it| create(it) }
      mock_login(:student)
    end

    after(:each) { logout! }

    describe 'GET /index' do
      it 'returns 403 Forbidden for HTML requests' do
        get items_url, as: :html
        expect(response.status).to eq(403)
        expect(response.content_type).to start_with('text/html')
        expect(response.body).to include('restricted to UC BEARS administrators')
      end

      it 'returns the items for JSON requests' do
        get items_url, as: :json

        expect(response).to be_successful
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_an(Array)

        expected_items = Item.order(:title)
        expect(parsed_response.size).to eq(expected_items.size)

        expected_items.each_with_index do |item, i|
          expect(parsed_response[i]).to eq(expected_json(item))
        end
      end
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

      describe 'exception handling' do
        it 'returns a JSON response for an arbitrary error' do
          exception_class = StandardError

          expected_status = 500
          expected_message = 'Help I am trapped in an integration test'
          allow(Item).to receive(:all).and_raise(exception_class, expected_message)

          get items_url, as: :json
          expect_json_error(expected_status, expected_message)
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

          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to be_a(Hash)

          expect(parsed_response['success']).to eq(false)

          parsed_error = parsed_response['error']
          expect(parsed_error).to be_a(Hash)
          expect(parsed_error['code']).to eq(422)

          errors = parsed_error['errors']
          messages = errors.map { |err| err['message'] }
          expect(messages.size).to eq(2)
          expect(messages).to include(Item::MSG_INVALID_DIRECTORY)
          expect(messages).to include('Copies must be greater than or equal to 0')
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

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to start_with('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_a(Hash)

        expect(parsed_response['success']).to eq(false)

        parsed_error = parsed_response['error']
        expect(parsed_error).to be_a(Hash)
        expect(parsed_error['code']).to eq(403)

        errors = parsed_error['errors']
        messages = errors.map { |err| err['message'] }
        expect(messages.size).to eq(1)
        expect(messages.first).to eq(Item::MSG_CANNOT_DELETE_COMPLETE_ITEM)
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

    describe 'GET /processing' do
      it 'returns the list of in-process directories' do
        symlinks = []
        begin
          final_root = Lending.stage_root_path(:final).expand_path
          processing_root = Lending.stage_root_path(:processing).expand_path

          factory_names = %i[
            complete_item active_item incomplete_no_images
            incomplete_no_marc incomplete_no_manifest incomplete_marc_only
          ]

          factory_names.each do |f|
            dir = attributes_for(f)[:directory]
            final_dir = final_root.join(dir)
            processing_dir = processing_root.join(dir)
            expect(processing_dir).not_to exist # just to be sure
            FileUtils.ln_s(final_dir, processing_dir, verbose: true)
            symlinks << processing_dir
          end
          expect(Lending.each_processing_dir.map(&:expand_path)).to contain_exactly(*symlinks) # just to be sure

          get processing_url, as: :json
          expect(response).to be_successful

          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to be_a(Array)
          expect(parsed_response.size).to eq(symlinks.size)

          symlinks.each do |l|
            directory = l.basename.to_s

            result = parsed_response.find { |r| r['path'] == l.to_s }
            expect(result).not_to be_nil

            expect(result['path']).to eq(l.to_s)
            expect(result['directory']).to eq(directory)
            expect(result['exists']).to eq(true)
            actual_mtime = Time.parse(result['mtime'])
            expect(actual_mtime).to be_within(1.second).of(l.mtime)

            iiif_dir = IIIFDirectory.new(directory, stage: :processing)
            %w[page_images marc_record manifest].each do |attr|
              expected = iiif_dir.send("#{attr}?")
              actual = result["has_#{attr}"]
              expect(actual).to eq(expected), "Wrong result for #{directory} #{attr}; expected #{expected}, was #{actual}"
            end
          end
        ensure
          FileUtils.rm(symlinks)
        end
      end
    end
  end
end
