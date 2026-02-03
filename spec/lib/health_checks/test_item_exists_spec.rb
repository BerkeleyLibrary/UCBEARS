require 'rails_helper'

RSpec.describe HealthChecks::TestItemExists do
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

  describe '#check' do
    it 'marks success when an active item exists' do
      active_relation = double('ActiveRelation')
      inactive_relation = double('InactiveRelation')
      item = instance_double(Item)

      allow(Item).to receive(:active).and_return(active_relation)
      allow(active_relation).to receive(:first).and_return(item)

      allow(Item).to receive(:inactive).and_return(inactive_relation)
      allow(inactive_relation).to receive(:first).and_return(nil)

      run_check

      expect(check.message).to eq('Test item lookup succeeded')
    end

    it 'fails when no complete item exists (active and inactive are nil)' do
      active_relation = double('ActiveRelation')
      inactive_relation = double('InactiveRelation')

      allow(Item).to receive(:active).and_return(active_relation)
      allow(active_relation).to receive(:first).and_return(nil)

      allow(Item).to receive(:inactive).and_return(inactive_relation)
      allow(inactive_relation).to receive(:first).and_return(nil)

      run_check

      expect(check.message).to eq('Unable to locate complete item')
      expect_failed
    end

    it 'falls back to inactive item when no active item exists' do
      active_relation = double('ActiveRelation')
      inactive_relation = double('InactiveRelation')
      item = instance_double(Item)

      allow(Item).to receive(:active).and_return(active_relation)
      allow(active_relation).to receive(:first).and_return(nil)

      allow(Item).to receive(:inactive).and_return(inactive_relation)
      allow(inactive_relation).to receive(:first).and_return(item)

      run_check

      expect(check.message).to eq('Test item lookup succeeded')
    end

    it 'marks failure and message when an exception occurs' do
      active_relation = double('ActiveRelation')

      allow(Item).to receive(:active).and_return(active_relation)
      allow(active_relation).to receive(:first).and_raise(StandardError, 'boom')

      run_check

      expect(check.message).to eq('Error: failed to check item')
      expect_failed
    end
  end
end
