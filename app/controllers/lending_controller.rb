# TODO: split this up into multiple, more focused controllers
# rubocop:disable Metrics/ClassLength
class LendingController < ApplicationController

  # ------------------------------------------------------------
  # Helpers

  helper_method :lending_admin?, :manifest_url

  # ------------------------------------------------------------
  # Hooks

  before_action(:authenticate!)
  before_action(:require_lending_admin!, except: %i[view manifest check_out return])
  before_action(:ensure_lending_item!)
  before_action(:require_processed_item!, only: %i[view manifest])
  before_action(:use_patron_support_email!, only: %i[view manifest])

  # ------------------------------------------------------------
  # Controller actions

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

    if token_str.nil? && @loan.active?
      token_str = current_user.borrower_token.token_str
      redirect_to(lending_view_path(directory:, token: token_str))
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
    if @item.update(lending_item_params)
      flash!(:success, t('items.update.success'))
      redirect_to lending_show_url(directory:)
    else
      render_with_errors(:edit, @item.errors, t('items.update.failed', dir: @item.directory))
    end
  end

  def check_out
    @loan = @item.check_out_to(patron_identifier)
    if @loan.persisted?
      flash!(:success, t('loans.check_out.success'))
      # TODO: can we get Rails to just parameterize the token as a string?
      token_str = current_user.borrower_token.token_str
      redirect_to lending_view_url(directory:, token: token_str)
    else
      render_with_errors(:view, @loan.errors, t('loans.check_out.failed', title: @item.title))
    end
  end

  def return
    loan = active_loan || most_recent_loan
    if loan.nil? || loan.returned?
      flash!(:danger, Item::MSG_NOT_CHECKED_OUT)
    else
      loan.return!
      flash!(:success, t('loans.return.success'))
    end
    redirect_to lending_view_url(directory:)
  end

  def activate
    if @item.active?
      flash!(:info, t('items.activate.already_active'))
    else
      @item.copies = 1 if @item.copies < 1
      @item.update!(active: true)
      flash!(:success, t('items.activate.success'))
    end
    redirect_to(items_path)
  end

  def deactivate
    if @item.inactive?
      flash!(:info, t('items.deactivate.already_inactive'))
    elsif @item.update(active: false)
      flash!(:success, t('items.deactivate.success'))
    end

    redirect_to(items_path)
  end

  def destroy
    if @item.complete?
      logger.warn('Failed to delete non-incomplete item', @item.directory)
      flash!(:danger, t('items.destroy.item_not_incomplete'))
    else
      @item.destroy!
      flash!(:success, t('items.destroy.success'))
    end

    redirect_to(items_path)
  end

  def reload
    begin
      refresh_and_notify
    rescue StandardError => e
      msg = t('items.reload.failed', msg: e.message)
      logger.error(msg, e)
      flash!(:danger, msg)
    end

    redirect_to lending_show_url(directory: @item.directory)
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def refresh_and_notify
    changes = @item.refresh_marc_metadata!(raise_if_missing: true)
    if changes.empty?
      flash!(:info, t('items.reload.no_changes'))
    else
      logger.info("MARC metadata for #{@item.id} reloaded", changes.transform_values { |(v2, v1)| { from_value: v1, to_value: v2 } })
      flash!(:success, t('items.reload.success'))
    end
  end

  def populate_view_flash
    flash_now!(:danger, t('loans.view.expired')) if most_recent_loan&.expired? # TODO: something less awkward
    return unless (reason_unavailable = @loan.reason_unavailable)

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
    @active_loan ||= Loan.active.find_by(**loan_args)
  end

  def most_recent_loan
    @most_recent_loan ||= Loan.where(**loan_args).order(:updated_at).last
  end

  def manifest_url
    lending_manifest_url(directory:)
  end

  # ------------------------------
  # Parameter methods

  # item lookup parameter (pseudo-ID)
  def directory
    params.require(:directory)
  end

  # create/update parameters
  def lending_item_params # TODO: better/more consistent name
    params.require(:item).permit(:directory, :title, :author, :publisher, :physical_desc, :copies, :active, term_ids: [])
  end

  # loan lookup parameters
  def loan_args # TODO: better/more consistent name
    {
      item: ensure_lending_item!,
      patron_identifier:
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

  def ensure_lending_item!
    @item ||= Item.find_by!(directory:)
  end

  def ensure_lending_item_loan!
    require_eligible_patron!

    # TODO: stop requiring an empty loan object
    @loan = existing_loan || Loan.new(**loan_args)
  end

end
# rubocop:enable Metrics/ClassLength
