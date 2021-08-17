require 'rails_helper'
require 'patron_helper'

module CalNet
  # Lisa Weber's UID, hard-coded in FrameworkUsers
  STACK_REQUEST_ADMIN_UID = '7165'.freeze

  # Fake user with LIBR-framework-lending-admins group management
  LENDING_ADMIN_UID = '5551214'.freeze

  # Fake user with LIBR-framework-admins group management
  FRAMEWORK_ADMIN_ID = Patron::FRAMEWORK_ADMIN_ID
end

# Mocks a calnet login as the specified patron, and stubs the corresponding
# Millennium patron dump file. Suitable for calling from a before() block.
#
# @return [User] A user object created from the specified mock data (not the
#                actual object from the session)
def login_as_patron(patron_id)
  stub_patron_dump(patron_id)
  mock_calnet_login(patron_id)
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

# Wraps the provided block in login_as() / logout!() calls. Useful when it's
# not possible to know the patron ID in a before() block.
# @@yield [User] A user object created from the specified mock data
def with_patron_login(patron_id)
  user = login_as_patron(patron_id)
  yield user
rescue StandardError => e
  puts "#{e}\n\t#{e.backtrace.join("\n\t")}"
  raise
ensure
  logout!
end

def auth_hash_for(uid_or_patron_number)
  calnet_yml_file = "spec/data/calnet/#{Patron::Dump.escape_patron_id(uid_or_patron_number)}.yml"
  raise IOError, "No such file: #{calnet_yml_file}" unless File.file?(calnet_yml_file)

  YAML.load_file(calnet_yml_file)
end

# Mocks a calnet login as the specified patron
def mock_calnet_login(uid_or_patron_number)
  auth_hash = auth_hash_for(uid_or_patron_number)
  mock_omniauth_login(auth_hash)
end

def mock_omniauth_login(auth_hash)
  OmniAuth.config.mock_auth[:calnet] = auth_hash
  do_get login_path

  Rails.application.env_config['omniauth.auth'] = auth_hash
  do_get omniauth_callback_path(:calnet)

  User.from_omniauth(auth_hash)
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
  if respond_to?(:page) && page.driver.respond_to?(:follow_redirects?)
    was_enabled = page.driver.follow_redirects?
    begin
      page.driver.options[:follow_redirects] = false
      yield
    ensure
      page.driver.options[:follow_redirects] = was_enabled
    end
  else
    yield
  end
end
