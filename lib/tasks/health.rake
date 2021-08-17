namespace :health do
  desc 'Query the healthcheck endpoint'
  task check: :environment do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.get(Rails.application.routes.url_helpers.health_path)
    puts session.response.body
    exit 1 if session.response.server_error?
  end
end
