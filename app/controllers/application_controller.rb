# Base class for all controllers
class ApplicationController < ActionController::Base
  include ExceptionHandling

  # TODO: make this configurable
  SUPPORT_EMAIL_STAFF = 'helpbox@library.berkeley.edu'.freeze
  SUPPORT_EMAIL_PATRON = 'eref-library@berkeley.edu'.freeze

  # Value of the "Questions?" mailto link in the footer
  # @return [String]
  def support_email
    @support_email || SUPPORT_EMAIL_STAFF
  end
  helper_method :support_email

  # @see https://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection/ClassMethods.html
  protect_from_forgery with: :exception

  # Require that the current user be authenticated
  #
  # @return [void]
  # @raise [Error::UnauthorizedError] If the user is not
  #   authenticated
  def authenticate!
    raise Error::UnauthorizedError, "Endpoint #{controller_name}/#{action_name} requires authentication" unless authenticated?

    yield current_user if block_given?
  end

  # Return whether the current user is authenticated
  #
  # @return [Boolean]
  def authenticated?
    current_user.authenticated?
  end
  helper_method :authenticated?

  # Return the current user
  #
  # This always returns a user object, even if the user isn't authenticated.
  # Call {User#authenticated?} to determine if they were actually auth'd, or
  # use the shortcut {#authenticated?} to see if the current user is auth'd.
  #
  # @return [User]
  def current_user
    @current_user ||= User.from_session(session).tap(&method(:ensure_session_count))
  end
  helper_method :current_user

  def render_with_errors(view, errors, log_message)
    logger.error(log_message, errors.full_messages)
    render_422(view, errors)
  end

  def render_422(view, errors, locals: {})
    flash.now[:danger] = errors.full_messages
    render(view, status: :unprocessable_entity, locals: locals)
  end

  # Sign in the user by storing their data in the session
  #
  # @param [User]
  # @return [void]
  def sign_in(user)
    session[:user] = user
  end

  # Sign out the current user by clearing all session data
  #
  # @return [void]
  def sign_out
    reset_session
  end

  def lending_admin?
    current_user.lending_admin?
  end

  def require_lending_admin!
    authenticate!
    return if lending_admin?

    raise Error::ForbiddenError, 'This page is restricted to UC BEARS administrators.'
  end

  def eligible_patron?
    current_user.ucb_student? || current_user.ucb_faculty? || current_user.ucb_staff?
  end

  def require_eligible_patron!
    authenticate!
    return if eligible_patron?

    raise Error::ForbiddenError, 'This page is restricted to active UC Berkeley faculty, staff, and students.'
  end

  # TODO: make this less awkward
  def use_patron_support_email!
    @support_email = SUPPORT_EMAIL_PATRON
  end

  private

  def ensure_session_count(user)
    return if SessionCounter.exists_for?(user)

    logger.info("No session count found for user #{user.uid} with existing session; initializing")
    SessionCounter.increment_count_for(user)
  end
end
