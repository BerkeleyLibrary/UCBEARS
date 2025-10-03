# ------------------------------------------------------------
# Dependencies

require 'spec_helper'

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'

require 'support/system_spec_helper'

# ------------------------------------------------------------
# RSpec configuration

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :system) do
    # System specs need truncation since Selenium runs in a separate process
    DatabaseCleaner.strategy = :truncation
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.after(:each, type: :system) do
    # Ensure browser session doesn’t bleed into the next test
    Capybara.reset_sessions!
  end

  config.include(SystemSpecHelper, type: :system)
end

# ------------------------------------------------------------
# FactoryBot

require 'support/factory_bot'

# ------------------------------------------------------------
# Alma

require 'support/alma'

# ------------------------------------------------------------
# Jbuilder templates

# TODO: move to spec/support
def expect_json_error(expected_status, expected_message)
  expect(response).not_to be_successful
  expect(response).to have_http_status(expected_status)
  expect(response.content_type).to start_with('application/json')

  parsed_response = JSON.parse(response.body)
  expect(parsed_response).to be_a(Hash)
  expect(parsed_response['success']).to eq(false)

  parsed_error = parsed_response['error']
  expect(parsed_error).to be_a(Hash)
  expect(parsed_error['code']).to eq(response.status)
  expect(parsed_error['message']).to eq(expected_message)

  err_array = parsed_error['errors']
  expect(err_array).to be_an(Array)
  expect(err_array.size).to eq(1)
  err_0 = err_array[0]
  expect(err_0).to be_a(Hash)
  expect(err_0['location']).to eq(request.original_fullpath)
end

# ------------------------------------------------------------
# Calnet

# TODO: move to spec/support
module CalnetHelper
  IDS = {
    student: '5551212'.freeze,
    faculty: '5551213'.freeze,
    staff: '5551214'.freeze,
    lending_admin: '5551215'.freeze,
    retiree: '5551216'.freeze
  }.freeze

  def cas_logout_url
    "https://#{Rails.application.config.cas_host}/cas/logout"
  end

  def mock_login(type)
    auth_hash = mock_auth_hash(type)
    mock_omniauth_login(auth_hash)
  end

  def mock_user_without_login(type)
    auth_hash = mock_auth_hash(type)
    User.from_omniauth(auth_hash)
  end

  # TODO: port this to Framework
  def mock_omniauth_login(auth_hash)
    last_signed_in_user = nil

    # We want the actual user object from the session, but system specs don't provide
    # access to it, so we intercept it at sign-in
    allow_any_instance_of(SessionsController).to receive(:sign_in).and_wrap_original do |m, *args|
      last_signed_in_user = args[0]
      m.call(*args)
    end
    log_in_with_omniauth(auth_hash)

    last_signed_in_user
  end

  def mock_auth_hash(type)
    raise ArgumentError, "Unknown user type: #{type.inspect}" unless (id = uid_for(type))

    auth_hash_for(id)
  end

  def uid_for(type)
    IDS[type]
  end

  def auth_hash_for(uid)
    calnet_yml_file = "spec/data/calnet/#{uid}.yml"
    raise IOError, "No such file: #{calnet_yml_file}" unless File.file?(calnet_yml_file)

    YAML.load_file(calnet_yml_file)
  end

  # Logs out. Suitable for calling in an after() block.
  def logout!
    # Selenium doesn't know anything about webmock and will just hit the real logout path,
    # so we only hit it in request specs
    unless respond_to?(:page)
      stub_request(:get, cas_logout_url).to_return(status: 200)
      do_get logout_path
    end

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

  private

  def log_in_with_omniauth(auth_hash)
    OmniAuth.config.mock_auth[:calnet] = auth_hash
    do_get login_path

    Rails.application.env_config['omniauth.auth'] = auth_hash
    do_get omniauth_callback_path(:calnet)
  end

  def can_disable_redirects?
    respond_to?(:page) && page.driver.respond_to?(:follow_redirects?)
  end
end

RSpec.configure do |config|
  config.include(CalnetHelper)
end
