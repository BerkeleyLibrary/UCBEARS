# ------------------------------------------------------------
# Dependencies

require 'spec_helper'

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'

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
end

# ------------------------------------------------------------
# FactoryBot

require 'support/factory_bot'

# ------------------------------------------------------------
# Calnet

module CalnetHelper
  IDS = {
    student: '05551212'.freeze,
    faculty: '05551213'.freeze,
    staff: '05551214'.freeze,
    lending_admin: '05551215'.freeze,
    retiree: '05551216'.freeze
  }.freeze

  def mock_login(type)
    auth_hash = mock_auth_hash(type)
    mock_omniauth_login(auth_hash)
  end

  def mock_user_without_login(type)
    auth_hash = mock_auth_hash(type)
    User.from_omniauth(auth_hash)
  end

  def mock_omniauth_login(auth_hash)
    OmniAuth.config.mock_auth[:calnet] = auth_hash
    do_get login_path

    Rails.application.env_config['omniauth.auth'] = auth_hash
    do_get omniauth_callback_path(:calnet)

    return request.session[:user] if request # request specs

    User.from_omniauth(auth_hash) # TODO: something better for system specs
  end

  def mock_auth_hash(type)
    raise ArgumentError, "Unknown user type: #{type.inspect}" unless (id = IDS[type])

    auth_hash_for(id)
  end

  def auth_hash_for(uid)
    calnet_yml_file = "spec/data/calnet/#{uid}.yml"
    raise IOError, "No such file: #{calnet_yml_file}" unless File.file?(calnet_yml_file)

    YAML.load_file(calnet_yml_file)
  end

  # Logs out. Suitable for calling in an after() block.
  def logout!
    stub_request(:get, 'https://auth-test.berkeley.edu/cas/logout').to_return(status: 200)
    without_redirects { do_get logout_path }

    clear_login_state!
  end

  # Clears login state without actually loading SessionController#logout.
  # Use this if you want Capybara failure screenshots to capture the page
  # under test instead of the 'logout successful' page.
  def clear_login_state!
    # ActionDispatch::TestProcess#session delegates to request.session,
    # but doesn't check whether it's actually present
    request.reset_session if request

    OmniAuth.config.mock_auth[:calnet] = nil
    CapybaraHelper.delete_all_cookies if defined?(CapybaraHelper)
  end

  # Gets the specified URL, either via the driven browser (in a system spec)
  # or directly (in a request spec)
  def do_get(path)
    return visit(path) if respond_to?(:visit)

    get(path)
  end

  # Capybara Rack::Test mock browser is notoriously stupid about external redirects
  # https://github.com/teamcapybara/capybara/issues/1388
  def without_redirects
    return yield unless can_disable_redirects?

    page.driver.follow_redirects?.tap do |was_enabled|
      page.driver.options[:follow_redirects] = false
      yield
    ensure
      page.driver.options[:follow_redirects] = was_enabled
    end
  end

  private

  def can_disable_redirects?
    respond_to?(:page) && page.driver.respond_to?(:follow_redirects?)
  end
end

RSpec.configure do |config|
  config.include(CalnetHelper)
end
