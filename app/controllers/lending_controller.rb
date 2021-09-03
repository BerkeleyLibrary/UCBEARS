# TODO: split this up into multiple, more focused controllers
# rubocop:disable Metrics/ClassLength
class LendingController < ApplicationController

  # ------------------------------------------------------------
  # Constants

  PROFILE_INDEX_HTML = 'index-profile.html'.freeze
  PROFILE_STATS_HTML = 'stats-profile.html'.freeze

  # ------------------------------------------------------------
  # Helpers

  helper_method :lending_admin?, :manifest_url

  # ------------------------------------------------------------
  # Hooks

  before_action(:authenticate!)
  before_action(:require_lending_admin!, except: %i[view manifest check_out return])
  before_action(:ensure_lending_item!, except: %i[index stats profile_index profile_stats])
  before_action(:require_processed_item!, only: %i[view manifest])
  before_action(:use_patron_support_email!, only: %i[view manifest])

  # ------------------------------------------------------------
  # Controller actions

  def index
    render('application/not_found') && return unless current_user.lending_admin?

    ensure_lending_items!
  end

  # Index page, but generate a profile result
  def profile_index
    RubyProf.start
    ensure_lending_items!
    flash.now[:info] = "<a href=\"/#{PROFILE_INDEX_HTML}\">Profile generated.</a>"
    render(:index)
  ensure
    result = RubyProf.stop
    File.open(File.join(File.expand_path('../../public', __dir__), PROFILE_INDEX_HTML), 'w') do |f|
      RubyProf::GraphHtmlPrinter.new(result).print(f, min_percent: 2)
    end
  end

  def edit; end

  # Admin view
  def show; end

  # TODO: move this to StatsController
  # Stats
  def stats
    # TODO: load stats more efficiently
  end

  # TODO: move this to StatsController
  # Stats page, but generate a profile result
  def profile_stats
    RubyProf.start
    flash.now[:info] = "<a href=\"/#{PROFILE_STATS_HTML}\">Profile generated.</a>"
    render(:stats)
  ensure
    result = RubyProf.stop
    File.open(File.join(File.expand_path('../../public', __dir__), PROFILE_STATS_HTML), 'w') do |f|
      RubyProf::GraphHtmlPrinter.new(result).print(f, min_percent: 2)
    end
  end

  # Patron view
  # TODO: separate actions for with/without token,
  #       separate views for with/without active loan
  def view
    if (token_str = params[:token])
      update_user_token(token_str)
    end
    ensure_lending_item_loan!

    if token_str.nil? && @lending_item_loan.active?
      token_str = current_user.borrower_token.token_str
      redirect_to(lending_view_path(directory: directory, token: token_str))
    else
      populate_view_flash
    end
  end

  def manifest
    require_active_loan! unless lending_admin?

    manifest = @lending_item.to_json_manifest(manifest_url)
    render(json: manifest)
  end

  # ------------------------------
  # Form handlers

  def update
    unless @lending_item.update(lending_item_params)
      return render_with_errors(:edit, @lending_item.errors, "Updating #{@lending_item.directory} failed")
    end

    flash[:success] = 'Item updated.'
    redirect_to lending_show_url(directory: directory)
  end

  def check_out
    @lending_item_loan = @lending_item.check_out_to(patron_identifier)
    return render_with_errors(:view, @lending_item_loan.errors, "Checking out #{@lending_item.directory} failed") unless @lending_item_loan.persisted?

    flash[:success] = 'Checkout successful.'
    # TODO: can we get Rails to just parameterize the token as a string?
    token_str = current_user.borrower_token.token_str
    redirect_to lending_view_url(directory: directory, token: token_str)
  end

  def return
    if active_loan
      active_loan.return!
      flash[:success] = 'Item returned.'
    else
      flash[:danger] = LendingItem::MSG_NOT_CHECKED_OUT
    end

    redirect_to lending_view_url(directory: directory)
  end

  def activate
    if @lending_item.active?
      flash[:info] = 'Item already active.'
    else
      @lending_item.copies = 1 if @lending_item.copies < 1
      @lending_item.update!(active: true)
      flash[:success] = 'Item now active.'
    end
    redirect_to(:index)
  end

  def deactivate
    if @lending_item.inactive?
      flash[:info] = 'Item already inactive.'
    elsif @lending_item.update(active: false)
      flash[:success] = 'Item now inactive.'
    end

    redirect_to(:index)
  end

  def destroy
    if @lending_item.complete?
      logger.warn('Failed to delete non-incomplete item', @lending_item.debug_hash)
      flash[:danger] = 'Only incomplete items can be deleted.'
    else
      @lending_item.destroy!
      flash[:success] = 'Item deleted.'
    end

    redirect_to(:index)
  end

  def reload
    begin
      refresh_and_notify
    rescue StandardError => e
      msg = "Error reloading MARC metadata: #{e}"
      logger.error(msg, e)
      flash[:danger] = msg
    end

    redirect_to lending_show_url(directory: @lending_item.directory)
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def refresh_and_notify
    raise ArgumentError, "No MARC record found at #{@lending_item.marc_path}" unless @lending_item.has_marc_record?

    changes = @lending_item.refresh_marc_metadata!
    if changes.empty?
      flash[:info] = 'No changes found.'
    else
      logger.info("MARC metadata for #{@lending_item.id} reloaded", changes.transform_values { |(v2, v1)| { from_value: v1, to_value: v2 } })
      flash[:success] = 'MARC metadata reloaded.'
    end
  end

  def populate_view_flash
    flash.now[:danger] ||= []
    flash.now[:danger] << 'Your loan term has expired.' if most_recent_loan&.auto_returned? # TODO: something less awkward
    flash.now[:danger] << reason_unavailable unless available?
  end

  # ------------------------------
  # Private accessors

  def patron_identifier
    current_user.borrower_id
  end

  def existing_loan
    @existing_loan ||= active_loan || most_recent_loan
  end

  def active_loan
    @active_loan ||= LendingItemLoan.active.find_by(**loan_args)
  end

  def most_recent_loan
    @most_recent_loan ||= LendingItemLoan.where(**loan_args).order(:updated_at).last
  end

  def available?
    @lending_item.available? || @lending_item_loan.active?
  end

  def reason_unavailable
    @lending_item.reason_unavailable
  end

  def manifest_url
    lending_manifest_url(directory: directory)
  end

  # ------------------------------
  # Parameter methods

  # item lookup parameter (pseudo-ID)
  def directory
    params.require(:directory)
  end

  # create/update parameters
  def lending_item_params # TODO: better/more consistent name
    params.require(:lending_item).permit(:directory, :title, :author, :publisher, :physical_desc, :copies, :active)
  end

  # loan lookup parameters
  def loan_args # TODO: better/more consistent name
    {
      lending_item: ensure_lending_item!,
      patron_identifier: patron_identifier
    }
  end

  # ------------------------------
  # Utility methods

  def update_user_token(token_str)
    current_user.update_borrower_token(token_str)
    sign_in(current_user) # TODO: something less hacky
  end

  def require_processed_item!
    require_eligible_patron! unless lending_admin? # TODO: require_eligible_patron! explicitly
    item = ensure_lending_item!

    raise ActiveRecord::RecordNotFound, item.reason_incomplete unless item.complete?
  end

  def require_active_loan!
    require_eligible_patron!

    raise Error::ForbiddenError, LendingItem::MSG_NOT_CHECKED_OUT unless active_loan
  end

  def ensure_lending_items!
    LendingItemLoan.return_overdue_loans!
    LendingItem.scan_for_new_items!
  end

  def ensure_lending_item!
    @lending_item ||= LendingItem.find_by!(directory: directory)
  end

  def ensure_lending_item_loan!
    require_eligible_patron!

    # TODO: stop requiring an empty loan object
    @lending_item_loan = existing_loan || LendingItemLoan.new(**loan_args)
  end

end
# rubocop:enable Metrics/ClassLength
