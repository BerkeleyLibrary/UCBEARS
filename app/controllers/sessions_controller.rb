# Handle user sessions and omniauth (CAS) callbacks
#
# When a user attempts to access a restricted resource, we redirect them (via
# an {ErrorHandling} hook) to the #new action. This sets the return url, if
# it's known, and forwards them on to Calnet for authentication. Calnet
# returns them (via Omniauth) to the #callback method, which stores their
# info into the session.
#
# The nitty gritty of Calnet authentication is handled mostly by Omniauth.
#
# @see https://github.com/omniauth/omniauth
class SessionsController < ApplicationController
  # Redirect the user to Calnet for authentication
  def new
    redirect_args = { origin: params[:url] || request.base_url }.to_query
    redirect_to("/auth/calnet?#{redirect_args}", allow_other_host: true)
  end

  # Generate a new user session using data returned from a valid Calnet login
  def callback
    logger.debug({ msg: 'Received omniauth callback', omniauth: auth_params })

    @user = User.from_omniauth(auth_params).tap do |user|
      sign_in(user)
      log_signin(user)
    end

    redirect_url = (request.env['omniauth.origin'] || root_path) # TODO: better default redirect path
    redirect_to(redirect_url, allow_other_host: true)
  end

  # Logout the user by redirecting to CAS logout screen
  def destroy
    sign_out

    # TODO: make this play better with Selenium tests
    redirect_to(cas_logout_url, allow_other_host: true)
  end

  # Require login, then:
  # - redirect administrators to "Manage Items"
  # - return 403 Forbidden for other users
  def index
    require_lending_admin!

    redirect_to(items_path)
  end

  private

  def auth_params
    request.env['omniauth.auth']
  end

  def cas_base_uri
    cas_host = Rails.application.config.cas_host
    URI.parse("https://#{cas_host}")
  end

  def cas_logout_url
    BerkeleyLibrary::Util::URIs.append(cas_base_uri, '/cas/logout').to_s
  end

  def log_signin(user)
    # NOTE: We explicitly log as user.to_s, not the full object,
    #       because we want to be sure not to log borrower_id
    logger.debug({ msg: 'Signed in user', user: user.to_s })

    SessionCounter.increment_count_for(user)
  end
end
