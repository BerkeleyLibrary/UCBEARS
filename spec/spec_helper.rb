# ------------------------------------------------------------
# Rails

ENV['RAILS_ENV'] = 'test'

# ------------------------------------------------------------
# Dependencies

require 'colorize'
require 'webmock/rspec'

require 'simplecov' if ENV['COVERAGE']

# ------------------------------------------------------------
# RSpec configuration

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation

  config.around(:each) do |example|
    # prevent running out of file handles-- see https://github.com/teamcapybara/capybara#gotchas
    # but only on system tests since it makes WebMock less useful
    # -- see https://github.com/bblimke/webmock/issues/955
    allow_real_http_connections = (example.metadata[:type] == :system)

    WebMock.disable_net_connect!(
      allow_localhost: true,
      net_http_connect_on_start: allow_real_http_connections
    )
    example.run
  ensure
    WebMock.allow_net_connect!
  end

  # Required for shared contexts (e.g. in ssh_helper.rb); see
  # https://relishapp.com/rspec/rspec-core/docs/example-groups/shared-context#background
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
