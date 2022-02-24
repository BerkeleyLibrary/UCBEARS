require 'rails_helper'

describe 'collect.rb' do
  it 'collects' do
    collect_rb_path = File.expand_path('../../bin/lending/collect.rb', __dir__)
    expect(File.executable?(collect_rb_path)).to eq(true)

    Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |tmpdir|
      lending_root = File.join(tmpdir, 'ucbears')
      FileUtils.mkdir(lending_root)
      FileUtils.cp_r('spec/data/lending/problems/ready', lending_root)

      stage_dirs = %i[processing final].each_with_object({}) do |stage, roots|
        stage_root = File.join(lending_root, stage.to_s)
        FileUtils.mkdir(stage_root)
        roots[stage] = stage_root
      end

      collect_env = {
        Lending::Config::ENV_ROOT => lending_root,
        Lending::Collector::ENV_STOP_FILE => File.join(lending_root, 'collect.stop')
      }

      system(collect_env, collect_rb_path)

      item_dir_final = File.join(stage_dirs[:final], 'b152240925_C070359919')
      expect(File.directory?(item_dir_final)).to eq(true)

      manifest = Lending::IIIFManifest.new(
        title: 'Tagebuch der Kulturwissenschaftlichen Bibliothek Warburg',
        author: 'Warburg, Aby',
        dir_path: item_dir_final
      )
      manifest.write_manifest!

      expected = File.read('spec/data/iiif/b152240925_C070359919.json')
      actual = manifest.manifest_path.read
      expect(actual).to eq(expected)
    end
  end
end
