require 'rails_helper'

RSpec.describe HealthChecks::LendingRootPath do
  subject(:check) { described_class.new }

  def run_check
    check.run
    check
  end

  def expect_failed
    if check.respond_to?(:failure?)
      expect(check.failure?).to be(true)
    else
      expect(check.instance_variable_get(:@failure_occurred)).to be(true)
    end
  end

  def expect_not_failed
    if check.respond_to?(:failure?)
      expect(check.failure?).to be(false)
    else
      expect(check.instance_variable_get(:@failure_occurred)).not_to be(true)
    end
  end

  describe '#check' do
    it 'fails when lending root path is not set' do
      allow(Lending::Config).to receive(:lending_root_path).and_return(nil)

      run_check

      expect(check.message).to eq('Lending root path not set')
      expect_failed
    end

    it 'fails when lending root is not a directory' do
      pn = Pathname.new('/tmp/lending-root')
      allow(pn).to receive(:directory?).and_return(false)

      allow(Lending::Config).to receive(:lending_root_path).and_return(pn)

      run_check

      expect(check.message).to eq("Not a directory: #{pn}")
      expect_failed
    end

    it 'fails when directory is not readable' do
      pn = Pathname.new('/tmp/lending-root')
      allow(pn).to receive(:directory?).and_return(true)
      allow(pn).to receive(:readable?).and_return(false)

      allow(Lending::Config).to receive(:lending_root_path).and_return(pn)

      run_check

      expect(check.message).to eq("Directory not readable: #{pn}")
      expect_failed
    end

    it 'does not fail when directory exists and is readable' do
      pn = Pathname.new('/tmp/lending-root')
      allow(pn).to receive(:directory?).and_return(true)
      allow(pn).to receive(:readable?).and_return(true)

      allow(Lending::Config).to receive(:lending_root_path).and_return(pn)

      run_check

      expect(check.message).to eq('Lending root path exists and is readable')
      expect_not_failed
    end

    it 'fails and sets message when an exception is raised' do
      allow(Lending::Config).to receive(:lending_root_path).and_raise(StandardError, 'boom')

      run_check

      expect(check.message).to match('Error: StandardError')
      expect_failed
    end
  end

  describe '#lending_root' do
    it 'memoizes Lending::Config.lending_root_path' do
      pn = Pathname.new('/tmp')
      allow(Lending::Config).to receive(:lending_root_path).and_return(pn)

      first = check.send(:lending_root)
      second = check.send(:lending_root)

      expect(first).to eq(pn)
      expect(second).to eq(pn)
      expect(Lending::Config).to have_received(:lending_root_path).once
    end
  end

  describe '#validate_lending_root' do
    it 'returns a failure when lending root is not a Pathname' do
      allow(Lending::Config).to receive(:lending_root_path).and_return('/tmp/not_a_pathname')

      result = check.send(:validate_lending_root)

      expect(result[:failure]).to be(true)
      expect(result[:message]).to match(/Not a pathname/)
    end
  end
end
