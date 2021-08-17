require 'rails_helper'
require 'lending'

module Lending
  describe Tileizer do
    let(:samples) { 'spec/data/lending/samples/b100523250_C044235662' }
    let(:samples_ready) { 'spec/data/lending/samples/ready/b100523250_C044235662' }
    let(:samples_final) { 'spec/data/lending/samples/final/b100523250_C044235662' }

    let(:ready) { 'spec/data/lending/ready/b11996535_B 3 106 704' }
    let(:infiles) { Dir.entries(ready).select { |f| PathUtils.image_ext?(f) }.sort }
    let(:final) { 'spec/data/lending/final/b11996535_B 3 106 704' }

    describe 'instance #tileize' do
      it 'tileizes to a specified file' do
        infile = File.join(samples_ready, '00000100.tif')
        expected = File.join(samples_final, '00000100.tif')

        Dir.mktmpdir do |outdir|
          basename = File.basename(infile)
          outfile = File.join(outdir, basename)
          tileizer = Tileizer.new(infile, outfile)
          tileizer.tileize!
          expect(tileizer).to be_tileized

          # Note: we can't just compare files because we need to handle minor differences
          # in output across OSes and libvips/libtiff versions, so let's leverage the code
          # we already wrote to detect image tiles for IIIF manifest generation

          page_expected = Lending::Page.new(expected)
          page_actual = Lending::Page.new(outfile)

          Page.assert_equal!(page_expected, page_actual)
        end
      end

      it 'tileizes a JPEG' do
        infile = File.join(samples_ready, '00000195.jpg')
        expected = File.join(samples_final, '00000195.tif')

        Dir.mktmpdir do |outdir|
          basename = File.basename(expected)
          outfile = File.join(outdir, basename)
          tileizer = Tileizer.new(infile, outfile)
          tileizer.tileize!
          expect(tileizer).to be_tileized

          # Note: we can't just compare files because we need to handle minor differences
          # in output across OSes and libvips/libtiff versions, so let's leverage the code
          # we already wrote to detect image tiles for IIIF manifest generation

          page_expected = Lending::Page.new(expected)
          page_actual = Lending::Page.new(outfile)

          aggregate_failures 'output image' do
            %i[width height tile_scale_factors].each do |attr|
              expected_val = page_expected.send(attr)
              actual_val = page_actual.send(attr)
              expect(actual_val).to eq(expected_val), "#{attr}: expected #{expected_val}, got #{actual_val}"
            end
          end
        end
      end
    end

    describe 'class #tileize' do
      it 'tileizes to a specified directory' do
        infile = File.join(samples_ready, '00000100.tif')
        expected = File.join(samples_final, '00000100.tif')

        Dir.mktmpdir do |outdir|
          basename = File.basename(infile)
          outfile = Tileizer.tileize(infile, outdir)
          expect(outfile.to_s).to eq(File.join(outdir, basename))
          expect(outfile.exist?).to eq(true)

          # Note: we can't just compare files because we need to handle minor differences
          # in output across OSes and libvips/libtiff versions, so let's leverage the code
          # we already wrote to detect image tiles for IIIF manifest generation

          page_expected = Lending::Page.new(expected)
          page_actual = Lending::Page.new(outfile)

          aggregate_failures 'output image' do
            %i[width height tile_scale_factors].each do |attr|
              expected_val = page_expected.send(attr)
              actual_val = page_actual.send(attr)
              expect(actual_val).to eq(expected_val), "#{attr}: expected #{expected_val}, got #{actual_val}"
            end
          end
        end
      end

      describe 'tileizing a file to a directory' do
        context 'with skip_existing: true' do
          it 'skips an existing file' do
            expect(Vips::Image).not_to receive(:new_from_file)
            infile = File.join(samples_ready, '00000100.tif')
            Dir.mktmpdir do |outdir|
              outfile = File.join(outdir, File.basename(infile))
              FileUtils.touch(outfile)
              Tileizer.tileize(infile, outdir, skip_existing: true)
            end
          end
        end

        it 'tileizes a JPEG' do
          infile = File.join(samples_ready, '00000195.jpg')
          expected = File.join(samples_final, '00000195.tif')

          Dir.mktmpdir do |outdir|
            basename = File.basename(expected)
            outfile = File.join(outdir, basename)
            Tileizer.tileize(infile, outdir)

            # Note: we can't just compare files because we need to handle minor differences
            # in output across OSes and libvips/libtiff versions, so let's leverage the code
            # we already wrote to detect image tiles for IIIF manifest generation

            page_expected = Lending::Page.new(expected)
            page_actual = Lending::Page.new(outfile)

            aggregate_failures 'output image' do
              %i[width height tile_scale_factors].each do |attr|
                expected_val = page_expected.send(attr)
                actual_val = page_actual.send(attr)
                expect(actual_val).to eq(expected_val), "#{attr}: expected #{expected_val}, got #{actual_val}"
              end
            end
          end
        end
      end

      describe 'tileizing a file to a file' do
        context 'with skip_existing: true' do
          it 'skips an existing file' do
            expect(Vips::Image).not_to receive(:new_from_file)
            infile = File.join(samples_ready, '00000100.tif')
            Dir.mktmpdir do |outdir|
              outfile = File.join(outdir, File.basename(infile))
              FileUtils.touch(outfile)
              Tileizer.tileize(infile, outfile, skip_existing: true)
            end
          end
        end
      end

    end

    it 'handles failures' do
      allow(Vips::Image).to receive(:new_from_file).and_raise('oops')
      infile = File.join(samples_ready, '00000100.tif')
      Dir.mktmpdir do |outdir|
        basename = File.basename(infile)
        outfile = File.join(outdir, basename)
        tileizer = Tileizer.new(infile, outfile)
        expect { tileizer.tileize! }.to raise_error(TileizeFailed)
        expect(File.exist?(outfile)).to eq(false)
      end
    end

    describe :tileize_all do

      it 'tileizes all files in a directory' do
        tiff_stems = infiles.filter_map { |f| PathUtils.stem(f) if PathUtils.tiff_ext?(f) }
        jpeg_stems = infiles.filter_map { |f| PathUtils.stem(f) if PathUtils.jpeg_ext?(f) }
        expect(jpeg_stems).not_to be_empty # just to be sure

        Dir.mktmpdir do |outdir|
          infiles.each do |f|
            stem = PathUtils.stem(f)
            infile = File.join(ready, f)
            outfile = File.join(outdir, "#{stem}.tif")

            # Prefer TIFF to JPEG if both exist
            if PathUtils.jpeg_ext?(f) && tiff_stems.include?(stem)
              expect(Vips::Image).not_to receive(:new_from_file).with(infile)
            else
              source_img = double(Vips::Image)
              expect(Vips::Image).to receive(:new_from_file).with(infile).and_return(source_img).ordered
              expect(source_img).to receive(:tiffsave).with(outfile.to_s, **Tileizer::VIPS_OPTIONS).ordered
            end
          end

          Tileizer.tileize_all(ready, outdir)
        end
      end

      it 'handles errors in individual files' do
        tiff_stems = infiles.filter_map { |f| PathUtils.stem(f) if PathUtils.tiff_ext?(f) }

        Dir.mktmpdir do |outdir|
          infiles.each_with_index do |f, i|
            stem = PathUtils.stem(f)
            infile = File.join(ready, f)
            outfile = File.join(outdir, "#{stem}.tif")

            # Prefer TIFF to JPEG if both exist
            if PathUtils.jpeg_ext?(f) && tiff_stems.include?(stem)
              expect(Vips::Image).not_to receive(:new_from_file).with(infile)
            else
              source_img = double(Vips::Image)
              expect(Vips::Image).to receive(:new_from_file).with(infile).and_return(source_img).ordered
              if i.odd?
                expect(source_img).to receive(:tiffsave).with(outfile.to_s, **Tileizer::VIPS_OPTIONS).and_raise('oops').ordered
              else
                expect(source_img).to receive(:tiffsave).with(outfile.to_s, **Tileizer::VIPS_OPTIONS).ordered
              end
            end
          end

          Tileizer.tileize_all(ready, outdir)
        end
      end

      context 'with skip_existing: true' do
        it 'skips an existing file' do
          indir = samples_ready
          infile = File.join(indir, '00000100.tif')
          Dir.mktmpdir do |outdir|
            outfile = File.join(outdir, File.basename(infile))
            FileUtils.touch(outfile)

            expect(Vips::Image).not_to receive(:new_from_file).with(infile.to_s, **Tileizer::VIPS_OPTIONS)
            Tileizer.tileize_all(indir, outdir, skip_existing: true)
          end
        end
      end
    end
  end
end
