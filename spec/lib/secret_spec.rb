require 'rails_helper'
require 'base64'

describe Docker::Secret do
  attr_reader :tmpdir_path

  before do
    tmpdir = Dir.mktmpdir(File.basename(__FILE__, '.rb'))
    @tmpdir_path = Pathname.new(tmpdir)
  end

  after do
    FileUtils.remove_dir(tmpdir_path, true)
  end

  describe :setup_environment! do
    attr_reader :expected_secrets

    before do
      prefix = Time.now.to_i.to_s
      random = Random.new
      @expected_secrets = {}
      (0..8).each do |i|
        secret_name = "secret_#{prefix}_#{i}"
        secret = Base64.strict_encode64(random.bytes(128))
        expected_secrets[secret_name] = secret
        tmpdir_path.join(secret_name).binwrite(secret)
      end
    end

    after do
      expected_secrets.each_key { |k| ENV.delete(k) }
    end

    it 'injects secrets into the environment' do
      fileglob = "#{tmpdir_path}/*"
      Docker::Secret.setup_environment!(fileglob)
      expected_secrets.each do |secret_name, secret_value|
        expect(ENV[secret_name]).to eq(secret_value)
      end
    end
  end
end
