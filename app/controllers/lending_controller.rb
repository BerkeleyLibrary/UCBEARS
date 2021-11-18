# TODO: split this up into multiple, more focused controllers
# rubocop:disable Metrics/ClassLength
class LendingController < ApplicationController

  # ------------------------------------------------------------
  # Constants

  PROFILE_INDEX_HTML = 'index-profile.html'.freeze

  # ------------------------------------------------------------
  # Helpers

  helper_method :lending_admin?, :manifest_url

  # ------------------------------------------------------------
  # Hooks

  before_action(:authenticate!)
  before_action(:require_lending_admin!, except: %i[view manifest check_out return])
  before_action(:ensure_lending_item!, except: %i[index profile_index])
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
    with_profile(PROFILE_INDEX_HTML) do
      ensure_lending_items!
      render(:index)
    end
  end

  # TODO: merge 'edit' and 'show'
  def edit; end

  # Admin view
  def show; end

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

    manifest = @item.to_json_manifest(manifest_url)
    render(json: manifest)
  end

  # ------------------------------
  # Form handlers

  def update
    unless @item.update(lending_item_params)
      return render_with_errors(:edit, @item.errors, "Updating #{@item.directory} failed")
    end

    flash!(:success, 'Item updated.')
    redirect_to lending_show_url(directory: directory)
  end

  def check_out
    @lending_item_loan = @item.check_out_to(patron_identifier)
    return render_with_errors(:view, @lending_item_loan.errors, "Checking out #{@item.directory} failed") unless @lending_item_loan.persisted?

    flash!(:success, 'Checkout successful.')
    # TODO: can we get Rails to just parameterize the token as a string?
    token_str = current_user.borrower_token.token_str
    redirect_to lending_view_url(directory: directory, token: token_str)
  end

  def return
    loan = active_loan || most_recent_loan
    if loan.nil? || loan.returned?
      flash!(:danger, Item::MSG_NOT_CHECKED_OUT)
    else
      loan.return!
      flash!(:success, 'Item returned.')
    end
    redirect_to lending_view_url(directory: directory)
  end

  def activate
    if @item.active?
      flash!(:info, 'Item already active.')
    else
      @item.copies = 1 if @item.copies < 1
      @item.update!(active: true)
      flash!(:success, 'Item now active.')
    end
    redirect_to(:index)
  end

  def deactivate
    if @item.inactive?
      flash!(:info, 'Item already inactive.')
    elsif @item.update(active: false)
      flash!(:success, 'Item now inactive.')
    end

    redirect_to(:index)
  end

  def destroy
    if @item.complete?
      logger.warn('Failed to delete non-incomplete item', @item.debug_hash)
      flash!(:danger, 'Only incomplete items can be deleted.')
    else
      @item.destroy!
      flash!(:success, 'Item deleted.')
    end

    redirect_to(:index)
  end

  def reload
    begin
      refresh_and_notify
    rescue StandardError => e
      msg = "Error reloading MARC metadata: #{e}"
      logger.error(msg, e)
      flash!(:danger, msg)
    end

    redirect_to lending_show_url(directory: @item.directory)
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def refresh_and_notify
    raise ArgumentError, "No MARC record found at #{@item.marc_path}" unless @item.has_marc_record?

    changes = @item.refresh_marc_metadata!
    if changes.empty?
      flash!(:info, 'No changes found.')
    else
      logger.info("MARC metadata for #{@item.id} reloaded", changes.transform_values { |(v2, v1)| { from_value: v1, to_value: v2 } })
      flash!(:success, 'MARC metadata reloaded.')
    end
  end

  def populate_view_flash
    flash_now!(:danger, 'Your loan term has expired.') if most_recent_loan&.expired? # TODO: something less awkward
    return unless (reason_unavailable = @lending_item_loan.reason_unavailable)

    flash_now!(:danger, reason_unavailable)
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
    params.require(:item).permit(:directory, :title, :author, :publisher, :physical_desc, :copies, :active)
  end

  # loan lookup parameters
  def loan_args # TODO: better/more consistent name
    {
      item: ensure_lending_item!,
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

    raise Error::ForbiddenError, Item::MSG_NOT_CHECKED_OUT unless active_loan
  end

  def ensure_lending_items!
    Item.scan_for_new_items!
  end

  def ensure_lending_item!
    @item ||= Item.find_by!(directory: directory)
  end

  def ensure_lending_item_loan!
    require_eligible_patron!

    # TODO: stop requiring an empty loan object
    @lending_item_loan = existing_loan || LendingItemLoan.new(**loan_args)
  end

end
# rubocop:enable Metrics/ClassLength
