require 'rails_helper'
require 'tmpdir'

RSpec.describe HealthChecks::CompiledAssetsCheck do
  subject(:check) { described_class.new }

  around do |example|
    Dir.mktmpdir do |directory|
      @directory = directory
      example.run
    end
  end

  let(:assets) { described_class::ASSETS.to_h { |name| [name, "compiled-#{name}"] } }

  before do
    manifest = double('manifest', assets: assets, directory: @directory)
    allow(Rails.application).to receive(:assets_manifest).and_return(manifest)
    assets.each_value { |name| File.write(File.join(@directory, name), 'asset') }
  end

  it 'passes when required assets are in the manifest and on disk' do
    check.run
    expect(check.success?).to be true
  end

  it 'fails when an asset is absent from the manifest' do
    assets.delete('application.js')
    check.run
    expect(check.success?).to be false
    expect(check.message).to include('application.js')
  end

  it 'fails when a manifest entry points to a missing file' do
    File.delete(File.join(@directory, assets.fetch('application.js')))
    check.run
    expect(check.success?).to be false
    expect(check.message).to include('application.js')
  end
end
