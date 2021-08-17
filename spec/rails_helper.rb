# ------------------------------------------------------------
# Dependencies

require 'spec_helper'

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'

require 'ssh_helper'
require 'patron_helper'

# ------------------------------------------------------------
# RSpec configuration

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.around(:each, type: :request) do |example|
    handler = ApplicationController.remove_rescue_handler_for(StandardError)
    begin
      example.run
    ensure
      ApplicationController.restore_rescue_handler(handler) if handler
    end
  end
end

# ------------------------------------------------------------
# Helper methods

# Temporarily redirects log output to a StringIO object, runs
# the specified block, and returns the captured log output.
#
# @param &block The block to run
# @return [String] The log output
def capturing_log(&block)
  logdev = Rails.logger.instance_variable_get(:@logdev)
  dev_actual = logdev.instance_variable_get(:@dev)
  dev_tmp = StringIO.new
  begin
    logdev.instance_variable_set(:@dev, dev_tmp)
    block.call
  ensure
    logdev.instance_variable_set(:@dev, dev_actual)
  end
  dev_tmp.string
end
