require 'rails_helper'
require 'lending/page'

module Lending
  describe Page do
    let(:tiff_path) { 'spec/data/lending/samples/final/b100523250_C044235662/00000100.tif' }

    describe :new do
      it 'accepts a string path' do
        expected_path = Pathname.new(tiff_path)
        page = Page.new(tiff_path)
        expect(page.tiff_path).to eq(expected_path)
      end

      it 'accepts a Pathname object' do
        expected_path = Pathname.new(tiff_path)
        page = Page.new(expected_path)
        expect(page.tiff_path).to eq(expected_path)
      end
    end

    context 'with a valid TIFF file' do
      let(:page) { Page.new(tiff_path) }

      describe :basename do
        it 'extracts the basename' do
          expected_basename = File.basename(tiff_path)
          expect(page.basename).to eq(expected_basename)
        end
      end

      describe :number do
        it 'extracts the page number as an int' do
          expect(page.number).to eq(100)
        end
      end

      describe :txt_path do
        it 'finds the txt path' do
          txt_path = Pathname.new(tiff_path.sub(/\.tif$/, '.txt'))
          expect(page.txt_path).to eq(txt_path)
        end
      end
    end

    context 'without a valid TIFF file' do
      describe :new do
        it 'rejects a nonexistent file' do
          expect { Page.new('not-a-real.tiff') }.to raise_error(ArgumentError)
        end

        it 'rejects an existing non-TIFF file' do
          txt_path = tiff_path.sub(/\.tif$/, '.txt')
          expect(File.exist?(txt_path)).to eq(true) # just to be sure
          expect { Page.new(txt_path) }.to raise_error(ArgumentError)
        end

        it 'rejects a legit TIFF with a non-page-number filename' do
          Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |dir|
            non_page_tiff = File.join(dir, 'non-page.tif')
            FileUtils.cp(tiff_path, non_page_tiff)
            expect { Page.new(non_page_tiff).to raise_error(ArgumentError) }
          end
        end
      end
    end
  end
end
