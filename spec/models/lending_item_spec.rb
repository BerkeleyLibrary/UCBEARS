require 'rails_helper'

describe LendingItem, type: :model do
  before(:each) do
    allow(Rails.application.config).to receive(:iiif_final_dir).and_return('spec/data/lending/samples/final')
  end

  attr_reader :items, :processed, :incomplete, :active

  context 'without existing items' do
    describe :scan_for_new_items! do
      it 'creates new items' do
        expected_dirs = Pathname.new(LendingItem.iiif_final_root).children.select { |d| Lending::PathUtils.item_dir?(d) }
        items = LendingItem.scan_for_new_items!
        expect(items.size).to eq(expected_dirs.size)
      end
    end
  end

  context 'with existing items' do

    before(:each) do
      @items = [
        {
          title: 'Villette',
          author: 'Brontë, Charlotte',
          directory: 'b155001346_C044219363',
          copies: 1
        },
        {
          title: 'The Great Depression in Europe, 1929-1939',
          author: 'Clavin, Patricia',
          directory: 'b135297126_C068087930',
          copies: 3
        },
        {
          title: 'The Plan of St. Gall',
          author: 'Horn, Walter',
          directory: 'b100523250_C044235662',
          copies: 6,
          active: true
        },
        {
          title: 'Pamphlet',
          author: 'Canada. Department of Agriculture.',
          directory: 'b11996535_B 3 106 704',
          copies: 2
        }
      ].map { |item_attributes| LendingItem.create!(**item_attributes) }

      @processed = items.select(&:complete?)
      @incomplete = items.reject(&:complete?)
      @active = @processed.select(&:active?)
    end

    describe :complete? do
      it 'returns true only items with manifest templates and populated image directories' do
        items.each do |item|
          should_be_complete = item.has_iiif_dir? && item.has_page_images? && item.iiif_manifest.has_template?
          expect(item.complete?).to eq(should_be_complete)

          if should_be_complete
            expect(item.reason_incomplete).to be_nil
          else
            expect(item.reason_incomplete).not_to be_nil
          end
        end
        expect(processed).not_to be_empty
      end
    end

    describe :available? do
      it 'returns true if there are copies available' do
        active.each do |item|
          expect(item.available?).to eq(true)
        end
      end

      it 'returns false if there are no copies available' do
        active.each do |item|
          item.copies = 0
          expect(item.available?).to eq(false)
        end
      end

      it 'returns false if the item has not been processed' do
        incomplete.each do |item|
          expect(item.available?).to eq(false)
        end
      end

      it 'returns false if all copies are checked out' do
        active.each do |item|
          item.copies.times { |i| item.check_out_to!("patron-#{i}") }
          expect(item.available?).to eq(false)
        end
      end
    end

    describe :iiif_manifest do
      it 'returns the IIIFItem if the item has been processed' do
        processed.each do |item|
          iiif_item = item.iiif_manifest
          expect(iiif_item).to be_a(Lending::IIIFManifest)
          expect(iiif_item.title).to eq(item.title)
          expect(iiif_item.author).to eq(item.author)
          expect(iiif_item.dir_path.to_s).to eq(item.iiif_dir)
        end
      end

      it 'returns nil if the item is has no IIIF directory or no page images' do
        unmanifestable = items.reject { |item| item.has_iiif_dir? && item.has_page_images? }
        expect(unmanifestable).not_to be_nil

        unmanifestable.each { |item| expect(item.iiif_manifest).to be_nil }
      end
    end

  end

  describe :states do
    attr_reader :items

    before(:each) do
      @items = [
        {
          title: 'The Plan of St. Gall : a study of the architecture & economy of life in a paradigmatic Carolingian monastery',
          author: 'Horn, Walter',
          directory: 'b100523250_C044235662',
          copies: 3,
          active: true
        },
        {
          title: 'The great depression in Europe, 1929-1939',
          author: 'Clavin, Patricia.',
          directory: 'b135297126_C068087930',
          copies: 1,
          active: false
        },
        {
          title: 'Villette',
          author: 'Brontë, Charlotte',
          directory: 'b155001346_C044219363',
          copies: 0,
          active: false
        },
        {
          title: 'Pamphlet.',
          author: 'Canada. Department of Agriculture.',
          directory: 'b11996535_B 3 106 704',
          copies: 0,
          active: false
        }
      ].map { |item_attributes| LendingItem.create!(**item_attributes) }
    end

    def processed
      items.select(&:complete?)
    end

    def incomplete
      items.reject(&:complete?)
    end

    def active
      processed.select(&:active?)
    end

    def inactive
      processed.reject(&:active?)
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

    describe :marc_metadata do
      attr_reader :items_with_marc
      attr_reader :items_without_marc

      before(:each) do
        @items_with_marc = []
        @items_without_marc = []
        items.each do |item|
          marc_xml = File.join(item.iiif_dir, 'marc.xml')
          (File.exist?(marc_xml) ? @items_with_marc : @items_without_marc) << item
        end
      end
      it 'returns the MARC metadata for items that have it' do
        expect(items_with_marc).not_to be_empty # just to be sure

        aggregate_failures :marc_metadata do
          items_with_marc.each do |item|
            md = item.marc_metadata
            expect(md).to be_a(Lending::MarcMetadata), "Expected MARC metadata for item #{item.directory}, got #{md.inspect}"
          end
        end
      end

      it "returns nil for items that don't" do
        expect(items_without_marc).not_to be_empty # just to be sure
        aggregate_failures :marc_metadata do
          items_without_marc.each do |item|
            md = item.marc_metadata
            expect(md).to be_nil, "Expected MARC metadata for item #{item.directory} to be nil, got #{md.inspect}"
          end
        end

      end
    end
  end
end
