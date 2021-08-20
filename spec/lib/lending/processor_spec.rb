require 'rails_helper'

module Lending
  describe Processor do

    let(:item) do
      attributes_for(:active_item).tap do |attrs|
        record_id, barcode = attrs[:directory].split('_')
        attrs[:record_id] = record_id
        attrs[:barcode] = barcode
      end
    end
    let(:ready_dir) { 'spec/data/lending/ready' }

    attr_reader :tmpdir, :processor

    before(:each) do
      @tmpdir = Dir.mktmpdir(File.basename(__FILE__, '.rb'))

      directory = item[:directory]
      indir = File.join(ready_dir, directory)
      outdir = File.join(tmpdir, directory)
      Dir.mkdir(outdir)
      @processor = Processor.new(indir, outdir)
    end

    after(:each) do
      FileUtils.remove_dir(tmpdir, true)
    end

    it 'extracts the record ID' do
      expect(processor.record_id).to eq(item[:record_id])
    end

    it 'extracts the barcode' do
      expect(processor.barcode).to eq(item[:barcode])
    end

    it 'extracts the author' do
      expect(processor.author).to eq(item[:author])
    end

    it 'extracts the title' do
      expect(processor.title).to eq(item[:title])
    end

    describe :process do
      let(:expected_dir) { Pathname.new('spec/data/lending/final').join(item[:directory]) }

      before(:each) do
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
