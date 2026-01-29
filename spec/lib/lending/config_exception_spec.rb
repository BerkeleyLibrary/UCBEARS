require 'rails_helper'

RSpec.describe Lending::ConfigException do
  it 'is a StandardError subclass' do
    expect(described_class).to be < StandardError
  end
end
