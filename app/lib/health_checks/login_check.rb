module HealthChecks
  class LoginCheck < OkComputer::Check
    def check
      response = Rack::MockRequest.new(Rails.application).get('/login', 'HTTPS' => 'on')
      mark_message "GET /login returned status #{response.status}"
      mark_failure unless response.status == 200
    rescue StandardError => e
      mark_message "GET /login failed: #{e.class.name}"
      mark_failure
    end
  end
end
