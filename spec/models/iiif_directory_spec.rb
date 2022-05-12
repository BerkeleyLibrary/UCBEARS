require 'rails_helper'

describe IIIFDirectory do
  before do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

  describe 'string representations' do
    attr_reader :iiif_directory, :expected_path

    before do
      item = create(:active_item)
      @iiif_directory = item.iiif_directory
      final_dir = Lending::Config.lending_root_path.join('final')
      @expected_path = final_dir.join(item.directory).expand_path
    end

    describe :to_s do
      it 'returns the path' do
        expect(iiif_directory.to_s).to eq(expected_path.to_s)
      end
    end

    describe :inspect do
      it 'includes the path' do
        expect(iiif_directory.inspect).to include(expected_path.to_s)
      end
    end
  end

  describe :first_image_url_path do
    it 'returns the first image' do
      directory = attributes_for(:complete_item)[:directory]
      iiif_directory = IIIFDirectory.new(directory)
      url_path = iiif_directory.first_image_url_path
      expected_path = BerkeleyLibrary::Util::Paths.join(directory, '00000001.tif')
      expect(url_path).to eq(expected_path)
    end

    it 'raises Errno::ENOENT if there are no page images' do
      directory = attributes_for(:incomplete_no_images)[:directory]
      iiif_directory = IIIFDirectory.new(directory)
      expect { iiif_directory.first_image_url_path }.to raise_error(Errno::ENOENT)
    end

    it 'raises Errno::ENOENT if the directory does not exist' do
      directory = attributes_for(:incomplete_no_directory)[:directory]
      iiif_directory = IIIFDirectory.new(directory)
      expect { iiif_directory.first_image_url_path }.to raise_error(Errno::ENOENT)
    end
  end

  describe :fetch do
    attr_reader :cache

    before do
      @cache = IIIFDirectory.send(:cache)
      @cache.clear
    end

    it 'caches results' do
      item = create(:active_item)
      iiif_directory = IIIFDirectory.fetch(item.directory)
      expect(item.iiif_directory).to be(iiif_directory)

      iiif_directory_2 = IIIFDirectory.fetch(item.directory)
      expect(iiif_directory_2).to be(iiif_directory)
    end

    it 'creates a new object if not found in cache' do
      item = create(:active_item)
      item_iiif_directory = item.iiif_directory

      cache.clear

      iiif_directory = IIIFDirectory.fetch(item.directory)
      expect(iiif_directory).not_to be(item_iiif_directory)
    end
  end
end
