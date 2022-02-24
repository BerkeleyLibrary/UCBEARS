require 'rails_helper'

module Lending
  describe Processor do
    attr_reader :item, :ready_dir, :expected_dir, :tmpdir, :directory, :indir, :outdir, :processor

    before(:all) do
      @item = attributes_for(:active_item).tap do |attrs|
        record_id, barcode = attrs[:directory].split('_')
        attrs[:record_id] = record_id
        attrs[:barcode] = barcode
      end

      @ready_dir = 'spec/data/lending/ready'
      @expected_dir = Pathname.new('spec/data/lending/final').join(item[:directory])

      @tmpdir = Dir.mktmpdir(File.basename(__FILE__, '.rb'))

      @directory = item[:directory]
      @indir = File.join(ready_dir, directory)
      @outdir = File.join(tmpdir, directory)
      Dir.mkdir(outdir)
      @processor = Processor.new(indir, outdir)
    end

    after(:all) do
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
      before(:all) do
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

      it 'generates the manifest' do
        expected_manifest = expected_dir.join(Lending::IIIFManifest::MANIFEST_NAME)
        actual_manifest = processor.outdir.join(Lending::IIIFManifest::MANIFEST_NAME)
        expect(actual_manifest.exist?).to eq(true)

        expect(actual_manifest.read.strip).to eq(expected_manifest.read.strip)
      end
    end

    describe :verify do
      it 'raises a ProcessingError for a malformed manifest' do
        manifest_path = processor.outdir.join(Lending::IIIFManifest::MANIFEST_NAME)

        manifest = instance_double(IIIFManifest)
        allow(manifest).to receive(:manifest_path).and_return(manifest_path)
        allow(manifest).to receive(:has_manifest?).and_return(true)
        allow(manifest).to receive(:to_json_manifest).and_return('{ something that is not valid JSON }')

        expect { processor.verify(manifest) }.to raise_error(ProcessingFailed) do |e|
          expect(e.cause).to be_a(JSON::ParserError)
        end
      end
    end

    it 'handles MARCXML names by bib number with a check digit mismatch' do
      Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |tmp_ready|
        FileUtils.cp_r(indir, tmp_ready)
        tmp_indir = File.join(tmp_ready, File.basename(indir))

        marc_xml_name = item[:record_id].sub(/\d$/, '.xml')
        FileUtils.mv(File.join(tmp_indir, 'marc.xml'), File.join(tmp_indir, marc_xml_name))

        @processor = Processor.new(tmp_indir, outdir)
        processor.process!
      end

      expected_manifest = expected_dir.join(Lending::IIIFManifest::MANIFEST_NAME)
      actual_manifest = processor.outdir.join(Lending::IIIFManifest::MANIFEST_NAME)
      expect(actual_manifest.exist?).to eq(true)

      expect(actual_manifest.read.strip).to eq(expected_manifest.read.strip)
    end

    describe :new do
      it 'rejects bad directories' do
        bad_dirs = [
          'recordid_',
          '_barcode',
          'recordidandbarcodewithnounderscore',
          ' leading_space',
          'trailing_space ',
          "\u00A0leading_nbsp",
          "trailing_nbsp\u00A0",
          "\u202Fleading_narrow_nbsp",
          "trailing_narrow_nbsp\u202F",
          "control_charact\u008drs",
          "contr\u008dl_characters"
        ]
        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |tmp_root|
          tmp_in, tmp_out = %w[ready processing].map do |d|
            File.join(tmp_root, d).tap { |dir| FileUtils.mkdir(dir) }
          end

          aggregate_failures 'bad directories' do
            bad_dirs.each do |d|
              bad_indir = File.join(tmp_in, d).tap { |dir| FileUtils.mkdir(dir) }
              bad_outdir = File.join(tmp_out, d).tap { |dir| FileUtils.mkdir(dir) }

              msg = "#{CGI.escape(d).inspect} was not recognized as a bad directory"
              expect { Processor.new(bad_indir, bad_outdir) }.to raise_error(ArgumentError), msg
            end
          end
        end
      end
    end
  end
end
