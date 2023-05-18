# Base class for all controllers
# TODO: extract some concerns or something so we can shorten this
# rubocop:disable Metrics/ClassLength
class ApplicationController < ActionController::Base
  include ExceptionHandling
  include Pagy::Backend

  # ------------------------------------------------------------
  # Global controller configuration

  # @see https://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection/ClassMethods.html
  protect_from_forgery with: :exception

  # ------------------------------------------------------------
  # Global hooks

  after_action do
    pagy_headers_merge(@pagy) if @pagy
    merge_link_header
  end

  # ------------------------------------------------------------
  # Public methods

  # ------------------------------
  # Authentication/Authorization

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
  delegate :authenticated?, to: :current_user
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

  delegate :lending_admin?, to: :current_user

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

  # ------------------------------
  # Email helpers

  # TODO: make this configurable
  SUPPORT_EMAIL_STAFF = 'helpbox@library.berkeley.edu'.freeze
  SUPPORT_EMAIL_PATRON = 'eref-library@berkeley.edu'.freeze

  # Value of the 'Questions?' mailto link in the footer
  # @return [String]
  def support_email
    @support_email || SUPPORT_EMAIL_STAFF
  end
  helper_method :support_email

  # TODO: make this less awkward
  def use_patron_support_email!
    @support_email = SUPPORT_EMAIL_PATRON
  end

  # ------------------------------
  # Misc. utilities

  def public_dir
    File.expand_path('../../public', __dir__)
  end

  def merge_link_header
    return unless @links

    existing_link_header = response.headers['Link']
    link_rels = @links.map { |rel, link| %(<#{link}>; rel="#{rel}") }
    link_rels << existing_link_header if existing_link_header

    response.headers['Link'] = link_rels.join(', ')
  end

  # ------------------------------
  # Profiling

  def with_profile(report_filename, &)
    flash_now!(:info, t('application.profile.generating.html', report_filename:))
    do_profile(report_filename, &)
    self.profile_link = report_filename
  rescue StandardError => e
    logger.error(e)
    return if performed?

    flash_now!(:danger, t('application.profile.failed', msg: e.message))
    render('application/standard_error', locals: { exception: e })
  end

  # ------------------------------
  # Error pages

  def render_with_errors(view, errors, log_message)
    logger.error(log_message, errors.full_messages)
    render_422(view, errors)
  end

  def render_422(view, errors, locals: {})
    flash_now!(:danger, errors.full_messages)
    render(view, status: :unprocessable_entity, locals:)
  end

  # ------------------------------
  # Flash alerts

  def flash!(lvl, msg)
    add_flash(flash, lvl, msg)
  end

  def flash_now!(lvl, msg)
    add_flash(flash.now, lvl, msg)
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def profile_link=(report_filename)
    profile_url = BerkeleyLibrary::Util::URIs.append(request.base_url, report_filename)
    (@links ||= {})['profile'] = profile_url.to_s
  end

  def add_flash(flash_obj, lvl, msg)
    flash_array = ensure_flash_array(flash_obj, lvl)
    if msg.is_a?(Array)
      flash_array.concat(msg)
    else
      flash_array << msg
    end
  end

  def ensure_flash_array(flash_obj, lvl)
    return (flash_obj[lvl] = []) unless (current = flash_obj[lvl])

    current.is_a?(Array) ? current : (flash_obj[lvl] = Array(current))
  end

  def do_profile(report_filename, &block)
    RubyProf.stop if RubyProf.running?
    RubyProf.start
    begin
      block.call
    ensure
      write_profile_report(report_filename) if RubyProf.running?
    end
  end

  def write_profile_report(report_filename)
    result = RubyProf.stop
    File.open(File.join(public_dir, report_filename), 'w') do |f|
      RubyProf::GraphHtmlPrinter.new(result).print(f, min_percent: 2)
    end
  end

  def ensure_session_count(user)
    return if SessionCounter.exists_for?(user)

    logger.info("No session count found for user #{user.uid} with existing session; initializing")
    SessionCounter.increment_count_for(user)
  end
end
# rubocop:enable Metrics/ClassLength
