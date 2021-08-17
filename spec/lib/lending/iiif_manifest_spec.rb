require 'rails_helper'
require 'lending'

module Lending
  describe IIIFManifest do

    let(:manifest_url) { 'https://ucbears.example.edu/lending/b11996535_B%203%20106%20704/manifest' }
    let(:img_root_url) { 'https://ucbears.example.edu/iiif/' }

    let(:expected_manifest) { File.read('spec/data/lending/samples/manifest-b11996535.json') }

    attr_reader :manifest

    before(:each) do
      @manifest = IIIFManifest.new(
        title: 'Pamphlet',
        author: 'Canada. Department of Agriculture.',
        dir_path: 'spec/data/lending/final/b11996535_B 3 106 704'
      )
    end

    describe :to_json do
      it 'creates a manifest' do
        actual = manifest.to_json(manifest_url, img_root_url)
        expect(actual.strip).to eq(expected_manifest.strip)
      end
    end

    describe :to_erb do
      let(:expected_erb) { File.read('spec/data/lending/final/b11996535_B 3 106 704/manifest.json.erb') }

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
        image_dir_uri = UCBLIT::Util::URIs.append(img_root_url, ERB::Util.url_encode(manifest.dir_basename))

        actual = ERB.new(expected_erb).result(binding)
        expect(actual.strip).to eq(expected_manifest.strip)
      end
    end

    context 'mixed case' do
      attr_reader :tmpdir_path
      attr_reader :dir_path_upcase

      before(:each) do
        tmpdir = Dir.mktmpdir(File.basename(__FILE__, '.rb'))
        @tmpdir_path = Pathname.new(tmpdir)

        dir_path_orig = manifest.dir_path
        @dir_path_upcase = tmpdir_path.join(dir_path_orig.basename.to_s.gsub('b11996535', 'b11996535'.upcase))
        FileUtils.ln_s(dir_path_orig.realpath, dir_path_upcase)

        @manifest = IIIFManifest.new(
          title: 'Pamphlet',
          author: 'Canada. Department of Agriculture.',
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

      describe :to_json do
        it 'generates a manifest with the correct image path' do
          manifest_url_upcase = manifest_url.gsub('b11996535', 'b11996535'.upcase)
          expected = expected_manifest.gsub('b11996535', 'b11996535'.upcase).strip
          actual = manifest.to_json(manifest_url_upcase, img_root_url).strip
          expect(actual).to eq(expected)
        end
      end
    end
  end
end
