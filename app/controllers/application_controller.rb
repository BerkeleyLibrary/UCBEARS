# Base class for all controllers
class ApplicationController < ActionController::Base
  include ExceptionHandling

  # @!group Class Attributes
  # @!attribute [rw]
  # Value of the "Questions?" mailto link in the footer
  # @return [String]
  class_attribute :support_email, default: 'helpbox@library.berkeley.edu'
  helper_method :support_email
  # @!endgroup

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
    @current_user ||= User.from_session(session)
  end

  # Log an exception
  def log_error(error)
    # TODO: should BerkeleyLibrary::Logging take care of this?
    msg = {
      msg: error.message,
      error: error.inspect.to_s,
      cause: error.cause.inspect.to_s
    }
    msg[:backtrace] = error.backtrace if Rails.logger.level < Logger::INFO
    logger.error(msg)
  end

  # Sign in the user by storing their data in the session
  #
  # @param [User]
  # @return [void]
  def sign_in(user)
    session[:user] = user

    logger.debug({
                   msg: 'Signed in user',
                   user: session[:user]
                 })
  end

  # Sign out the current user by clearing all session data
  #
  # @return [void]
  def sign_out
    reset_session
  end
end
