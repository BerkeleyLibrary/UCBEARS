require 'rails_helper'

module Lending
  describe IIIFManifest do

    let(:manifest_url) { 'https://ucbears.example.edu/lending/b135297126_C068087930/manifest' }
    let(:img_root_url) { 'https://ucbears.example.edu/iiif/' }

    let(:expected_manifest) { File.read('spec/data/lending/samples/final/b135297126_C068087930/manifest.json') }

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
        expect(actual.strip).to eq(expected_manifest.strip)
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
          manifest.write_manifest_erb!
          expect { manifest.to_json_manifest(manifest_url, img_root_url) }.not_to raise_error
        end
      end
    end

    describe :to_erb do
      let(:expected_erb) { File.read('spec/data/lending/final/b135297126_C068087930/manifest.json.erb') }

      it 'can create an ERB' do
        expected = expected_erb
        actual = manifest.to_erb
        expect(actual.strip).to eq(expected.strip)
      end

      it 'generates an ERB that produces a valid manifest' do
        # local, passed to template via binding
        # noinspection RubyUnusedLocalVariable
        manifest_uri = URI(manifest_url)

        # local, passed to template via binding
        # noinspection RubyUnusedLocalVariable
        image_dir_uri = BerkeleyLibrary::Util::URIs.append(img_root_url, ERB::Util.url_encode(manifest.dir_basename))

        actual = ERB.new(expected_erb).result(binding)
        expect(actual.strip).to eq(expected_manifest.strip)
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

          expected = File.read('spec/data/lending/problems/final/b152240925_C070359919/manifest.json.erb')
            .gsub('<% aus New York', '<%% aus New York')

          actual = manifest.to_erb

          expect(actual.strip).to eq(expected.strip)
        end
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
  end
end
