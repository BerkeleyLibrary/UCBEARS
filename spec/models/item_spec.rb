require 'rails_helper'

describe Item, type: :model do
  let(:factory_names) do
    %i[
      inactive_item
      active_item
      incomplete_no_directory
      incomplete_no_images
      incomplete_no_marc
      incomplete_no_manifest
      incomplete_marc_only
    ]
  end

  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

  describe 'with active default term' do
    attr_reader :current_term

    before(:each) do
      @prev_default_term = Settings.default_term
      @current_term = create(:term, name: 'Test 1', start_date: Date.current - 1.days, end_date: Date.current + 1.days)
      Settings.default_term = current_term
    end

    after(:each) do
      Settings.default_term = @prev_default_term
    end

    describe :refresh_marc_metadata! do
      it 'refreshes the metadata' do
        original_item = create(:active_item)
        original_values = %i[author title publisher physical_desc].map { |attr| [attr, original_item.send(attr)] }.to_h

        modified_values = original_values.transform_values { |v| "not #{v}" }
        original_item.update!(**modified_values)
        expect(original_item.persisted?).to eq(true) # just to be sure
        modified_values.each { |attr, v| expect(original_item.send(attr)).to eq(v) } # just to be sure

        refreshed_item = Item.find(original_item.id).tap(&:refresh_marc_metadata!)
        original_values.each { |attr, v| expect(refreshed_item.send(attr)).to eq(v) }

        original_item.reload
        original_values.each { |attr, v| expect(original_item.send(attr)).to eq(v) }
      end

      it 'returns previous values when refreshing changes the metadata' do
        item = create(:active_item)
        original_values = %i[author title publisher physical_desc].map { |attr| [attr, item.send(attr)] }.to_h

        modified_values = original_values.transform_values { |v| "not #{v}" }
        item.update!(**modified_values)

        item.reload
        refreshed = item.refresh_marc_metadata!
        expected_changes = original_values.map { |attr, v| [attr, [modified_values[attr], v]] }.to_h
        expect(refreshed).to include(expected_changes)
      end

      it 'returns an empty hash when refreshing does not change the metadata' do
        item = create(:active_item)
        item.reload
        refreshed = item.refresh_marc_metadata!
        expect(refreshed).to be_empty
      end

      it "doesn't blow up on incomplete items" do
        items = factory_names
          .select { |n| n.to_s.start_with?('incomplete') }
          .map { |n| build(n).tap { |it| it.save(validate: false) } }

        sleep(1)

        items.each do |item|
          last_updated_at = item.updated_at
          expect { item.refresh_marc_metadata! }.not_to raise_error

          iiif_directory = item.iiif_directory
          expect(item.updated_at).to eq(last_updated_at) if iiif_directory.marc_metadata.nil?
        end
      end
    end

    describe 'validation' do
      it 'requires a parseable directory' do
        attributes = attributes_for(:active_item).tap do |attrs|
          attrs[:directory] = 'I am not a valid directory'
        end
        item = Item.create(attributes)
        expect(item.persisted?).to eq(false)
        messages = item.errors.full_messages.map { |msg| CGI.unescapeHTML(msg) }
        expect(messages).to include(Item::MSG_INVALID_DIRECTORY)
      end
    end

    describe :update do
      it 'updates (or appears to update) the manifest' do
        item = create(:active_item)

        original_title = item.title
        original_author = item.author
        original_manifest = item.to_json_manifest(Lending::IIIFManifest::MF_URL_PLACEHOLDER)

        new_title = 'The Great Depression in Europe, 1929-1939'
        new_author = 'Patricia Clavin'

        item.update!(title: new_title, author: new_author)
        new_manifest = item.to_json_manifest(Lending::IIIFManifest::MF_URL_PLACEHOLDER)

        expected_manifest = original_manifest
          .gsub(/(?<=")#{original_title}(?=")/, new_title)
          .gsub(/(?<=")#{original_author}(?=")/, new_author)
        expect(new_manifest).to eq(expected_manifest)
      end
    end

    context 'without existing items' do
      before(:each) do
        expect(Item.count).to eq(0) # just to be sure
      end

      describe :scan_for_new_items! do
        it 'creates new items' do
          expected_dirs = Lending
            .stage_root_path(:final).children
            .select do |d|
            Lending::PathUtils.item_dir?(d) &&
              d.join(Lending::MARC_XML_NAME).file?
          end
          items = Item.scan_for_new_items!
          expect(items.size).to eq(expected_dirs.size)
        end

        it 'populates the publication metadata' do
          items = Item.scan_for_new_items!
          items.each { |it| expect(it.publisher).not_to be_nil }
        end

        it 'sets the default term' do
          items = Item.scan_for_new_items!
          items.each do |item|
            expect(item.terms.count).to eq(1)
            expect(item.terms).to include(current_term)
            expect(item.next_active_term).to eq(current_term)
          end
        end
      end

      describe 'create' do
        it 'allows setting a term explicitly' do
          previous_term = create(:term, name: 'Test 2', start_date: Date.current - 10.days, end_date: Date.current - 5.days)
          attrs = attributes_for(:complete_item)
          attrs[:terms] = [previous_term]
          item = Item.create!(**attrs)
          expect(item.terms).to include(previous_term)
          expect(item.terms).not_to include(current_term)
        end
      end

      describe 'validation' do
        it "doesn't prevent activating items with no author" do
          item = create(:inactive_item)
          expect(item).to be_persisted # just to be sure

          item.update!(author: nil)
          item.update!(copies: 3, active: true)

          item.reload
          expect(item.author).to be_nil
          expect(item.active?).to eq(true)
        end
      end
    end

    context 'with existing items' do
      attr_reader :items

      before(:each) do
        expect(Item.count).to eq(0) # just to be sure
        # NOTE: we're deliberately not validating here, because we want some invalid items
        @items = factory_names.each_with_object({}) do |fn, items|
          items[fn] = build(fn).tap { |it| it.save!(validate: false) }
        end
      end

      describe :terms do
        it 'returns the default term(s)' do
          items.each_value { |item| expect(item.terms).to include(current_term) }
        end
      end

      describe :active? do
        it 'returns true for active items' do
          item = items[:active_item]
          expect(item.active).to eq(true) # just to be sure
          expect(item).to be_active
        end

        it 'returns false for inactive items' do
          item = items[:inactive_item]
          expect(item.active).to eq(false) # just to be sure
          expect(item.copies).to eq(0) # just to be sure
          expect(item).not_to be_active
        end

        it 'returns false for inactive items with copies' do
          item = items[:inactive_item]
          expect(item.active).to eq(false) # just to be sure
          expect(item.copies).to eq(0) # just to be sure
          item.update!(copies: 2)
          expect(item).not_to be_active
        end
      end

      describe :complete? do
        it 'returns false for items without IIIF directories' do
          item = items[:incomplete_no_directory]
          iiif_directory = item.iiif_directory
          expect(iiif_directory.exists?).to eq(false)
          expect(iiif_directory.page_images?).to eq(false)
          expect(iiif_directory.marc_record?).to eq(false)
          expect(iiif_directory.manifest_template?).to eq(false)
          expect(item).not_to be_complete
        end

        it 'returns false for items without page images' do
          item = items[:incomplete_no_images]
          iiif_directory = item.iiif_directory
          expect(iiif_directory.exists?).to eq(true)
          expect(iiif_directory.page_images?).to eq(false)
          expect(iiif_directory.marc_record?).to eq(true)
          expect(iiif_directory.manifest_template?).to eq(true)
          expect(item).not_to be_complete
        end

        it 'returns false for items without MARC records' do
          item = items[:incomplete_no_marc]
          iiif_directory = item.iiif_directory
          expect(iiif_directory.exists?).to eq(true)
          expect(iiif_directory.page_images?).to eq(true)
          expect(iiif_directory.marc_record?).to eq(false)
          expect(iiif_directory.manifest_template?).to eq(true)
          expect(item).not_to be_complete
        end

        it 'returns false for items without manifest templates' do
          item = items[:incomplete_no_manifest]
          iiif_directory = item.iiif_directory
          expect(iiif_directory.exists?).to eq(true)
          expect(iiif_directory.page_images?).to eq(true)
          expect(iiif_directory.marc_record?).to eq(true)
          expect(iiif_directory.manifest_template?).to eq(false)
          expect(item).not_to be_complete
        end

        it 'returns false for items without manifest templates or page images' do
          item = items[:incomplete_marc_only]
          expect(item.iiif_directory.exists?).to eq(true)
          expect(item.iiif_directory.page_images?).to eq(false)
          expect(item.iiif_directory.marc_record?).to eq(true)
          expect(item.iiif_directory.manifest_template?).to eq(false)
          expect(item).not_to be_complete
        end

        it 'returns true for complete items' do
          %i[inactive_item active_item].each do |fn|
            item = items[fn]

            expect(item.iiif_directory.exists?).to eq(true)
            expect(item.iiif_directory.page_images?).to eq(true)
            expect(item.iiif_directory.marc_record?).to eq(true)
            expect(item.iiif_directory.manifest_template?).to eq(true)
            expect(item).to be_complete
          end
        end

        describe :reason_unavailable do
          it 'returns an appropriate message for incomplete items' do
            item = items[:incomplete_no_directory]
            item.active = true
            item.copies = 3

            expect(item.reason_unavailable).to include(Item::MSG_INCOMPLETE)
          end
        end
      end

      describe :available? do
        it 'returns true if there are copies available' do
          item = items[:active_item]
          expect(item.copies_available).to be > 0 # just to be sure
          expect(item).to be_available
        end

        it 'returns false if there are no copies available' do
          item = items[:active_item]
          item.copies_available.times do |i|
            item.check_out_to("patron-#{i}")
          end
          expect(item.copies_available).to eq(0) # just to be sure
          expect(item).not_to be_available
        end

        it 'returns false if the item is incomplete' do
          items.each_value.reject(&:complete?).each do |item|
            expect(item).not_to be_available
          end
        end

        it 'returns false if the item is inactive' do
          item = items[:inactive_item]
          expect(item.copies_available).to eq(0) # just to be sure
          expect(item).not_to be_available

          item.update!(copies: 2)
          expect(item.copies_available).to be > 0 # just to be sure
          expect(item).not_to be_available
        end

        it 'returns false if the item is not for an active term' do
          item = items[:active_item]
          expect(item).to be_available # just to be sure

          future_term = Term.create(name: 'Future Term', start_date: Time.current + 1.week, end_date: Time.current + 1.month)
          expect(future_term).not_to be_current # just to be sure

          item.update!(terms: [future_term])
          expect(item.terms.count).to eq(1) # just to be sure
          expect(item.for_current_term?).to eq(false)
          expect(item.next_active_term).to eq(future_term)

          expect(item).not_to be_available
          expect(item.reason_unavailable).to include(Item::MSG_NOT_CURRENT_TERM)
          expect(item.reason_unavailable).to include(future_term.name)
        end
      end

      describe :iiif_manifest do
        let(:with_manifest) { %i[inactive_item active_item incomplete_no_images incomplete_no_marc] }

        it 'returns the manifest if the item has one' do
          with_manifest.each do |fn|
            item = items[fn]
            manifest = item.iiif_manifest
            expect(manifest).to be_a(Lending::IIIFManifest)
            expect(manifest.title).to eq(item.title)
            expect(manifest.author).to eq(item.author)
            expect(manifest.dir_path).to eq(item.iiif_directory.path)
          end
        end
      end

      describe :has_manifest_template? do
        let(:with_manifest) { %i[inactive_item active_item incomplete_no_images incomplete_no_marc] }

        it 'returns false if the item has no IIIF directory or no manifest' do
          items.each do |fn, item|
            next if with_manifest.include?(fn)

            expect(item.iiif_directory.manifest_template?).to eq(false)
          end
        end
      end

      describe :states do
        def complete
          items.values.select(&:complete?)
        end

        def incomplete
          items.values.reject(&:complete?)
        end

        def active
          complete.select(&:active?)
        end

        def inactive
          complete.reject(&:active?)
        end

        describe :active do
          it 'returns the active items' do
            expect(active).not_to be_empty
          end
        end

        describe :inactive do
          it 'returns the active items' do
            expect(inactive).not_to be_empty
          end
        end

        describe :incomplete do
          it 'returns the incomplete items' do
            expect(incomplete).not_to be_empty
          end
        end

      end

      describe :marc_metadata do
        attr_reader :items_with_marc
        attr_reader :items_without_marc

        before(:each) do
          @items_with_marc = []
          @items_without_marc = []
          items.each_value do |item|
            marc_xml = item.iiif_directory.marc_path
            (File.exist?(marc_xml) ? @items_with_marc : @items_without_marc) << item
          end
        end

        it 'returns the MARC metadata for items that have it' do
          expect(items_with_marc).not_to be_empty # just to be sure

          aggregate_failures do
            items_with_marc.each do |item|
              iiif_directory = item.iiif_directory
              md = iiif_directory.marc_metadata
              expect(md).to be_a(Lending::MarcMetadata), "Expected MARC metadata for item #{item.directory}, got #{md.inspect}"
            end
          end
        end

        it "returns nil for items that don't" do
          expect(items_without_marc).not_to be_empty # just to be sure
          aggregate_failures do
            items_without_marc.each do |item|
              iiif_directory = item.iiif_directory
              md = iiif_directory.marc_metadata
              expect(md).to be_nil, "Expected MARC metadata for item #{item.directory} to be nil, got #{md.inspect}"
            end
          end
        end
      end

      describe :search_by_metadata do
        it 'matches on title' do
          keyword = 'depression'

          expected = Item.where('title LIKE ?', "%#{keyword}%")
          expect(expected).to exist # just to be sure

          actual = Item.search_by_metadata(keyword)
          expect(actual).to contain_exactly(*expected)
        end

        it 'matches on author' do
          keyword = 'Clavin'

          expected = Item.where('author LIKE ?', "%#{keyword}%")
          expect(expected).to exist # just to be sure

          actual = Item.search_by_metadata(keyword)
          expect(actual).to contain_exactly(*expected)
        end

        it 'matches on publisher' do
          keyword = 'York'

          expected = Item.where('publisher LIKE ?', "%#{keyword}%")
          expect(expected).to exist # just to be sure

          actual = Item.search_by_metadata(keyword)
          expect(actual).to contain_exactly(*expected)
        end

        it 'matches on physical description' do
          keyword = 'ill'

          expected = Item.where('physical_desc LIKE ?', "%#{keyword}%")
          expect(expected).to exist # just to be sure

          actual = Item.search_by_metadata(keyword)
          expect(actual).to contain_exactly(*expected)
        end

        it 'ignores keyword order' do
          keyword = 'Patricia Clavin'

          expected = Item.where('author LIKE ?', '%Clavin%')
          expect(expected).to exist # just to be sure

          actual = Item.search_by_metadata(keyword)
          expect(actual).to contain_exactly(*expected)
        end

        it 'can be combined with other criteria' do
          keyword = 'Patricia Clavin'

          expected = Item.complete.where('author LIKE ?', '%Clavin%')
          expect(expected).to exist # just to be sure

          actual = Item.complete.search_by_metadata(keyword)
          expect(actual).to contain_exactly(*expected)

          actual.each { |it| expect(it).to be_complete } # just to be sure
        end

        it 'ignores case' do
          keyword = 'patricia clavin'

          expected = Item.where('author LIKE ?', '%Clavin%')
          expect(expected).to exist # just to be sure

          actual = Item.search_by_metadata(keyword)
          expect(actual).to contain_exactly(*expected)
        end
      end
    end
  end

  describe 'with future default term' do
    attr_reader :future_term

    before(:each) do
      @future_term = Term.create(name: 'Future Term', start_date: Time.current + 1.week, end_date: Time.current + 1.month)
      Settings.default_term = future_term
    end

    after(:each) do
      Settings.default_term = @prev_default_term
    end

    describe :create do
      it 'sets the default term' do
        items = Item.scan_for_new_items!
        expect(Item.exists?).to eq(true) # just to be sure

        items.each do |item|
          expect(item.terms.count).to eq(1)
          expect(item.next_active_term).to eq(future_term)
        end
      end
    end
  end

  describe 'without default term' do
    before(:each) do
      @prev_default_term = Settings.default_term
      Settings.default_term = nil
    end

    after(:each) do
      Settings.default_term = @prev_default_term
    end

    describe :create do
      it "doesn't set a term" do
        items = Item.scan_for_new_items!
        expect(Item.exists?).to eq(true) # just to be sure
        items.each do |item|
          expect(item.terms.count).to eq(0)
          expect(item.next_active_term).to be_nil
        end
      end
    end
  end
end
