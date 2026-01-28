require 'rails_helper'

RSpec.describe 'Health Check', type: :system do
  describe 'Checking system health' do
    it 'renders the health status as JSON when healthy' do
      visit '/health'
      json = JSON.parse(page.text)

      expect(json.dig('database', 'success')).to be true
    end

    it 'returns a failure status when a critical service is down' do
      failing_check_class = Class.new(OkComputer::Check) do
        def check
          mark_message 'Intentional failure for test'
          mark_failure
        end
      end

      begin
        OkComputer::Registry.register('failing-check', failing_check_class.new)

        visit '/health'
        json = JSON.parse(page.text)

        expect(json.dig('failing-check', 'success')).to be false
      ensure
        OkComputer::Registry.deregister('failing-check')
      end
    end
  end
end
