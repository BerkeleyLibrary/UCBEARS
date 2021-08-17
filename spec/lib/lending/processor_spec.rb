require 'rails_helper'
require 'lending'

module Lending
  describe Processor do

    let(:items) do
      [
        {
          title: 'The great depression in Europe, 1929-1939',
          author: 'Clavin, Patricia.',
          directory: 'b135297126_C068087930',
          record_id: 'b135297126',
          barcode: 'C068087930'
        },
        {
          title: 'The Plan of St. Gall : a study of the architecture & economy of life in a paradigmatic Carolingian monastery',
          author: 'Horn, Walter, 1908-1995.',
          directory: 'b100523250_C044235662',
          record_id: 'b100523250',
          barcode: 'C044235662'
        },
        {
          title: 'Pamphlet.',
          author: 'Canada. Department of Agriculture.',
          directory: 'b11996535_B 3 106 704',
          record_id: 'b11996535',
          barcode: 'B 3 106 704'
        }
      ]
    end

    let(:ready_dir) { 'spec/data/lending/samples/ready' }

    attr_reader :tmpdir, :processors

    before(:each) do
      @tmpdir = Dir.mktmpdir(File.basename(__FILE__, '.rb'))

      @processors = items.map do |item|
        directory = item[:directory]
        indir = File.join(ready_dir, directory)
        outdir = File.join(tmpdir, directory)
        Dir.mkdir(outdir)
        Processor.new(indir, outdir)
      end
    end

    after(:each) do
      FileUtils.remove_dir(tmpdir, true)
    end

    it 'extracts the record ID' do
      items.each_with_index do |item, i|
        processor = processors[i]
        expect(processor.record_id).to eq(item[:record_id])
      end
    end

    it 'extracts the barcode' do
      items.each_with_index do |item, i|
        processor = processors[i]
        expect(processor.barcode).to eq(item[:barcode])
      end
    end

    it 'extracts the author' do
      items.each_with_index do |item, i|
        processor = processors[i]
        expect(processor.author).to eq(item[:author])
      end
    end

    it 'extracts the title' do
      items.each_with_index do |item, i|
        processor = processors[i]
        expect(processor.title).to eq(item[:title])
      end
    end

    describe :process do
      let(:expected_dir) { Pathname.new('spec/data/lending/samples/final/b100523250_C044235662') }

      attr_reader :processor

      before(:each) do
        @processor = processors.find { |p| p.indir.basename == expected_dir.basename }
        processor.process!
      end

      it 'tileizes the images' do
        expected_tiffs = expected_dir.children.select { |p| PathUtils.tiff_ext?(p) }
        expect(expected_tiffs).not_to be_empty # just to be sure

        expected_tiffs.each do |expected_tiff|
          actual_tiff = processor.outdir.join(expected_tiff.basename)
          expect(actual_tiff.exist?).to eq(true)

          Page.assert_equal!(expected_tiff, actual_tiff)
        end
      end

      it 'copies the OCR text' do
        expected_txts = expected_dir.children.select { |p| p.extname.downcase == '.txt' }
        expect(expected_txts).not_to be_empty # just to be sure
        expected_txts.each do |expected_txt|
          actual_txt = processor.outdir.join(expected_txt.basename)
          expect(actual_txt.read).to eq(expected_txt.read)
        end
      end

      it 'generates the manifest template' do
        expected_template = expected_dir.join(Lending::IIIFManifest::MANIFEST_TEMPLATE_NAME)
        actual_template = processor.outdir.join(Lending::IIIFManifest::MANIFEST_TEMPLATE_NAME)
        expect(actual_template.exist?).to eq(true)

        expect(actual_template.read.strip).to eq(expected_template.read.strip)
      end
    end
  end
end
