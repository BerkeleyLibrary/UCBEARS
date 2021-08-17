# Base class for all controllers
class ApplicationController < ActionController::Base
  include ExceptionHandling

  # @!group Class Attributes
  # @!attribute [rw]
  # Value of the "Questions?" mailto link in the footer
  # @return [String]
  class_attribute :support_email, default: 'privdesk@library.berkeley.edu'
  helper_method :support_email
  # @!endgroup

  # Return 404 if the requested path is in ENV["LIT_HIDDEN_PATHS"]
  before_action :hide_paths

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
    @current_user ||= User.new(session[:user] || {})
  end

  # Log an exception
  def log_error(error)
    # TODO: share code w/ApplicationJob
    msg = {
      msg: error.message,
      error: error.inspect.to_s,
      cause: error.cause.inspect.to_s
    }
    msg[:backtrace] = error.backtrace if Rails.logger.level < Logger::INFO
    logger.error(msg)
  end

  # @return Regexp Pattern determining whether a request should be "hidden"
  #
  # For example, "LIT_HIDDEN_PATHS='foo bar.*'" will result in a regexp that
  # matches either "foo" OR "bar.*".
  def hidden_paths_re
    @_hidden_paths_re ||= Regexp.union(
      (ENV['LIT_HIDDEN_PATHS'] || '')
        .split.map(&:strip).reject(&:empty?).map { |s| Regexp.new(s) }
    )
  end

  # Before filter that 404s requests whose paths match hidden_paths_re
  def hide_paths
    hidden_paths_re.match(request.path) do
      render file: Rails.root.join('public/404.html'), status: :not_found
    end
  end

  # Perform a redirect but keep all existing request parameters
  #
  # This is a workaround for not being able to redirect a POST/PUT request.
  def redirect_with_params(opts = {})
    redirect_to request.parameters.update(opts)
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
