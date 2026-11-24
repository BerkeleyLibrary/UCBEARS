require 'rails_helper'

RSpec.describe HealthChecks::LoginCheck do
  subject(:check) { described_class.new }

  it 'passes when the real login page renders' do
    check.run
    expect(check.message).to eq('GET /login returned status 200')
    expect(check.success?).to be true
  end

  it 'fails when login rendering raises an error' do
    allow_any_instance_of(SessionsController).to receive(:new).and_raise(StandardError.new('broken layout'))
    check.run
    expect(check.success?).to be false
  end

  it 'fails when login redirects instead of rendering' do
    allow_any_instance_of(SessionsController).to receive(:new) do |controller|
      controller.redirect_to('/somewhere')
    end
    check.run
    expect(check.message).to eq('GET /login returned status 302')
    expect(check.success?).to be false
  end
end
