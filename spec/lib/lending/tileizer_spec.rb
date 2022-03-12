require 'rails_helper'

module Lending
  describe Tileizer do
    RSpec.shared_examples :tileize_all_examples do |ready|
      let(:infiles) { Dir.entries(ready).select { |f| PathUtils.image_ext?(f) }.sort }

      before do
        expect(infiles).not_to be_empty # just to be sure
      end

      it 'tileizes all images in a directory' do
        Dir.mktmpdir do |outdir|
          infiles.each do |f|
            stem = PathUtils.stem(f)
            infile = File.join(ready, f)
            outfile = File.join(outdir, "#{stem}.tif")
            source_img = double(Vips::Image)
            expect(Vips::Image).to receive(:new_from_file).with(infile).and_return(source_img).ordered
            expect(source_img).to receive(:tiffsave).with(outfile.to_s, **Tileizer::VIPS_OPTIONS).ordered
          end

          Tileizer.tileize_all(ready, outdir)
        end
      end

      it 'handles errors in individual files' do
        Dir.mktmpdir do |outdir|
          infiles.each_with_index do |f, i|
            stem = PathUtils.stem(f)
            infile = File.join(ready, f)
            outfile = File.join(outdir, "#{stem}.tif")

            source_img = double(Vips::Image)
            expect(Vips::Image).to receive(:new_from_file).with(infile).and_return(source_img).ordered

            expect(source_img).to receive(:tiffsave).with(outfile.to_s, **Tileizer::VIPS_OPTIONS).ordered do
              raise 'oops' if i.odd?
            end
          end

          Tileizer.tileize_all(ready, outdir)
        end
      end

      context 'with skip_existing: true' do
        it 'skips existing files' do
          Dir.mktmpdir do |outdir|
            infiles.each_with_index do |f, i|
              stem = PathUtils.stem(f)
              infile = File.join(ready, f)
              outfile = File.join(outdir, "#{stem}.tif")

              if i.odd?
                FileUtils.touch(outfile)
                expect(BerkeleyLibrary::Logging.logger).to receive(:info).with("Skipping existing file #{outfile}").ordered
                expect(Vips::Image).not_to receive(:new_from_file).with(infile)
              else
                expect(BerkeleyLibrary::Logging.logger).to receive(:info).with("Tileizing #{infile} to #{outfile}").ordered

                source_img = double(Vips::Image)
                expect(Vips::Image).to receive(:new_from_file).with(infile).and_return(source_img).ordered
                expect(source_img).to receive(:tiffsave).with(outfile.to_s, **Tileizer::VIPS_OPTIONS).ordered
              end
            end

            Tileizer.tileize_all(ready, outdir, skip_existing: true)
          end
        end
      end
    end

    describe :tileize_all do
      sample_root = 'spec/data/lending/samples'

      context 'with TIFF files' do
        include_examples :tileize_all_examples, File.join(sample_root, 'b135297126_C068087930_TIFF')
      end

      context 'with JPEG files' do
        include_examples :tileize_all_examples, File.join(sample_root, 'b135297126_C068087930_JPEG')
      end
    end
  end
end
