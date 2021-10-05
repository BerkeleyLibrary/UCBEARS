require 'rails_helper'

describe IIIFDirectory do
  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

  describe 'string representations' do
    attr_reader :iiif_directory, :expected_path

    before(:each) do
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
        expect(iiif_directory.to_s).to include(expected_path.to_s)
      end
    end
  end
end
