require 'rails_helper'

RSpec.describe 'Health Check', type: :system do
  describe 'Checking system health' do
    it 'renders the health status as JSON when healthy' do
      visit '/health'
      json = JSON.parse(page.text)

      expect(json.dig('database', 'success')).to be true
    end

    it 'returns a failure status when a critical service is down' do
      # 1. Inject an environment variable into the current process.
      # Note: For this to work in Docker, the Puma server must be
      # running in the same container or share the ENV.
      # A more robust way for Docker is to stub the ActiveRecord call itself:

      allow(ActiveRecord::Base).to receive(:connected?).and_return(false)
      # Wait! The above also only works in the test process.

      # INSTEAD: Let's use the Registry to register a temporary
      # failing check that doesn't rely on mocks.

      begin
        # Register a check that always fails
        OkComputer::Registry.register 'failing-check', OkComputer::HttpCheck.new('http://localhost:9999/nonexistent')

        visit '/health'

        json = JSON.parse(page.text)
        # Verify that at least one check failed
        expect(json.values.any? { |v| v['success'] == false }).to be true
      ensure
        # Always unregister to avoid bleeding into other tests
        OkComputer::Registry.deregister 'failing-check'
      end
    end
  end
end
