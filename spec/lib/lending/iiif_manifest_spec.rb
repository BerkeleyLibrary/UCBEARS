require 'rails_helper'

module Lending
  describe IIIFManifest do

    let(:manifest_url) { 'https://ucbears.test/lending/b135297126_C068087930/manifest' }
    let(:img_root_url) { 'http://iipsrv.test/iiif/' }

    let(:expected_manifest_raw) { File.read('spec/data/lending/final/b135297126_C068087930/manifest.json') }
    let(:expected_manifest) do
      img_dir_url = BerkeleyLibrary::Util::URIs.append(img_root_url, 'b135297126_C068087930')
      expected_manifest_raw.strip
        .gsub(IIIFManifest::MF_URL_PLACEHOLDER, manifest_url.to_s)
        .gsub(IIIFManifest::IMGDIR_URL_PLACEHOLDER, img_dir_url.to_s)
    end

    attr_reader :manifest

    before(:each) do
      @manifest = IIIFManifest.new(
        title: 'The great depression in Europe, 1929-1939',
        author: 'Clavin, Patricia.',
        dir_path: 'spec/data/lending/final/b135297126_C068087930'
      )
    end

    describe :to_json_manifest do
      it 'creates a manifest' do
        actual = manifest.to_json_manifest(manifest_url, img_root_url)
        expect(actual.strip).to eq(expected_manifest)
      end

      it 'handles OCR text containing ERB delimiters' do
        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |tmpdir|
          ready_dir = 'spec/data/lending/problems/ready/b152240925_C070359919'
          final_dir = File.join(tmpdir, File.basename(ready_dir))
          FileUtils.cp_r(ready_dir, final_dir)

          manifest = IIIFManifest.new(
            title: 'Tagebuch der Kulturwissenschaftlichen Bibliothek Warburg',
            author: 'Warburg, Aby',
            dir_path: final_dir
          )
          manifest.write_manifest!

          expected = File.read('spec/data/iiif/b152240925_C070359919.json')
          actual = manifest.manifest_path.read
          expect(actual).to eq(expected)

          expect { manifest.to_json_manifest(manifest_url, img_root_url) }.not_to raise_error
        end
      end

      it 'raises an error if no manifest file is present' do
        ready_dir = 'spec/data/lending/problems/ready/b152240925_C070359919'

        manifest = IIIFManifest.new(
          title: 'Tagebuch der Kulturwissenschaftlichen Bibliothek Warburg',
          author: 'Warburg, Aby',
          dir_path: ready_dir
        )

        expect { manifest.to_json_manifest(manifest_url, img_root_url) }.to raise_error(ArgumentError)
      end
    end

    context 'mixed case' do
      attr_reader :tmpdir_path
      attr_reader :dir_path_upcase

      before(:each) do
        tmpdir = Dir.mktmpdir(File.basename(__FILE__, '.rb'))
        @tmpdir_path = Pathname.new(tmpdir)

        dir_path_orig = manifest.dir_path
        @dir_path_upcase = tmpdir_path.join(dir_path_orig.basename.to_s.gsub('b135297126', 'b135297126'.upcase))
        FileUtils.ln_s(dir_path_orig.realpath, dir_path_upcase)

        @manifest = IIIFManifest.new(
          title: 'The great depression in Europe, 1929-1939',
          author: 'Clavin, Patricia.',
          dir_path: dir_path_upcase.to_s
        )
      end

      after(:each) do
        FileUtils.remove_dir(tmpdir_path, true)
      end

      describe :dir_path do
        it 'returns the exact path' do
          expect(manifest.dir_path).to eq(dir_path_upcase)
        end
      end

      describe :dir_basename do
        it 'returns the literal directory basename' do
          expect(manifest.dir_basename).to eq(dir_path_upcase.basename.to_s)
        end
      end

      describe :to_json_manifest do
        it 'generates a manifest with the correct image path' do
          manifest_url_upcase = manifest_url.gsub('b135297126', 'b135297126'.upcase)
          expected = expected_manifest.gsub('b135297126', 'b135297126'.upcase).strip
          actual = manifest.to_json_manifest(manifest_url_upcase, img_root_url).strip
          expect(actual).to eq(expected)
        end
      end
    end

    describe :update_manifest do
      let(:author_actual) { 'Clavin, Patricia.' }
      let(:title_actual) { 'The great depression in Europe, 1929-1939' }

      def unfix_manifest(src)
        src
          .gsub(/"(value|label)": "#{title_actual}"/, '"\\1": "The Great Depression in Europe, 1929-1939"')
          .gsub(/"(value|label)": "#{author_actual}"/, '"\\1": "Patricia Clavin"')
          .gsub('"label": "Image ', '"label": "Page ')
      end

      it 'updates a JSON manifest' do
        bad_manifest_json = unfix_manifest(expected_manifest_raw)

        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |dir|
          manifest_json_path = Pathname.new(dir).join('manifest.json')
          manifest_json_path.open('w') { |f| f.write(bad_manifest_json) }

          manifest = IIIFManifest.new(title: title_actual, author: author_actual, dir_path: dir)
          manifest.update_manifest!

          result_json = manifest_json_path.read
          expect(result_json).to eq(expected_manifest_raw)
        end
      end

      it 'adds title and author if missing' do
        bad_manifest_json = expected_manifest_raw.sub(/"metadata": \[[^]]+]/, '"metadata": []')

        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |dir|
          manifest_json_path = Pathname.new(dir).join('manifest.json')
          manifest_json_path.open('w') { |f| f.write(bad_manifest_json) }

          manifest = IIIFManifest.new(title: title_actual, author: author_actual, dir_path: dir)
          manifest.update_manifest!

          result_json = manifest_json_path.read
          expect(result_json).to eq(expected_manifest_raw)
        end
      end

      it 'updates an ERB manifest' do
        bad_manifest_erb = unfix_manifest(File.read('spec/data/iiif/b135297126_C068087930.json.erb'))

        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |dir|
          manifest_json_path = Pathname.new(dir).join('manifest.json')
          manifest_erb_path = Pathname.new(dir).join('manifest.json.erb')
          manifest_erb_path.open('w') { |f| f.write(bad_manifest_erb) }

          manifest = IIIFManifest.new(title: title_actual, author: author_actual, dir_path: dir)
          manifest.update_manifest!

          result_json = manifest_json_path.read
          expect(result_json).to eq(expected_manifest_raw)
        end
      end

      it 'writes a manifest de novo' do
        ready_dir = 'spec/data/lending/problems/ready/b152240925_C070359919'
        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |dir|
          final_dir = File.join(dir, File.basename(ready_dir))
          FileUtils.cp_r(ready_dir, final_dir)

          manifest = IIIFManifest.new(
            title: 'Tagebuch der Kulturwissenschaftlichen Bibliothek Warburg',
            author: 'Warburg, Aby',
            dir_path: final_dir
          )
          manifest.update_manifest!

          expected = File.read('spec/data/iiif/b152240925_C070359919.json')
          manifest_json_path = Pathname.new(final_dir).join('manifest.json')
          actual = manifest_json_path.read
          expect(actual).to eq(expected)
        end
      end
    end
  end
end
