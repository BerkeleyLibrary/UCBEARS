# rubocop:disable Metrics/ClassLength
class LendingController < ApplicationController

  # ------------------------------------------------------------
  # Configuration

  self.support_email = 'helpbox@library.berkeley.edu'

  # ------------------------------------------------------------
  # Helpers

  helper_method :sort_column, :sort_direction, :lending_admin?, :manifest_url

  # ------------------------------------------------------------
  # Hooks

  before_action(:ensure_lending_item!, except: %i[index new create profile])
  before_action(:require_processed_item!, only: [:manifest])
  before_action(:require_lending_admin!, except: %i[view manifest check_out return])
  before_action(:authenticate!)

  # ------------------------------------------------------------
  # Controller actions

  # ------------------------------
  # UI actions

  def index
    ensure_lending_items!
  end

  # Index page, but generate a profile result
  def profile
    RubyProf.start
    ensure_lending_items!
    render(:index)
  ensure
    result = RubyProf.stop
    File.open(File.join(File.expand_path('../../public', __dir__), 'profile.html'), 'w') do |f|
      RubyProf::GraphHtmlPrinter.new(result).print(f, min_percent: 2)
    end
  end

  def new
    @lending_item = LendingItem.new(copies: 0)
  end

  def edit; end

  # Admin view
  def show; end

  # Patron view
  # rubocop:disable Metrics/AbcSize
  def view
    ensure_lending_item_loan!
    flash.now[:danger] ||= []
    flash.now[:danger] << 'Your loan term has expired.' if most_recent_loan&.auto_returned? # TODO: something less awkward
    flash.now[:danger] << reason_unavailable unless available?
  end
  # rubocop:enable Metrics/AbcSize

  def manifest
    require_active_loan! unless lending_admin?

    manifest = @lending_item.to_json_manifest(manifest_url)
    render(json: manifest)
  end

  # ------------------------------
  # Form handlers

  def create
    @lending_item = LendingItem.create(lending_item_params)
    return render_422(:new, @lending_item.errors, locals: { item: @lending_item }) unless @lending_item.persisted?

    flash[:success] = 'Item created.'
    redirect_to lending_show_url(directory: @lending_item.directory)
  end

  def update
    return render_422(:edit, errors) unless @lending_item.update(lending_item_params)

    flash[:success] = 'Item updated.'
    redirect_to lending_show_url(directory: directory)
  end

  def check_out
    @lending_item_loan = @lending_item.check_out_to(patron_identifier)
    return render_422(:view, @lending_item_loan.errors) unless @lending_item_loan.persisted?

    flash[:success] = 'Checkout successful.'
    redirect_to lending_view_url(directory: directory)
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
    redirect_to(:lending)
  end

  def deactivate
    if @lending_item.inactive?
      flash[:info] = 'Item already inactive.'
    elsif @lending_item.update(active: false)
      flash[:success] = 'Item now inactive.'
    end

    redirect_to(:lending)
  end

  def destroy
    if @lending_item.complete?
      flash[:error] = 'Only incomplete items can be deleted.'
    else
      @lending_item.destroy!
      flash[:success] = 'Item deleted.'
    end

    redirect_to(:lending)
  end

  # ------------------------------------------------------------
  # Helper methods

  def sort_column
    params[:sort].tap { |col| return 'created_at' unless LendingItem.column_names.include?(col) }
  end

  def sort_direction
    params[:direction].tap { |dir| return 'desc' unless %w[asc desc].include?(dir) }
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def render_422(view, errors, locals: {})
    flash.now[:danger] = errors.full_messages
    render(view, status: :unprocessable_entity, locals: locals)
  end

  # ------------------------------
  # Private accessors

  def patron_identifier
    current_user.lending_id
  end

  def lending_admin?
    current_user.lending_admin?
  end

  def eligible_patron?
    current_user.ucb_student? || current_user.ucb_faculty? || current_user.ucb_staff?
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
    params.require(:lending_item).permit(:directory, :title, :author, :copies, :active)
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

  def require_processed_item!
    require_eligible_patron! unless lending_admin?
    item = ensure_lending_item!

    raise ActiveRecord::RecordNotFound, item.reason_incomplete unless item.complete?
  end

  def require_lending_admin!
    authenticate!
    return if lending_admin?

    raise Error::ForbiddenError, 'This page is restricted to UC BEARS administrators.'
  end

  def require_eligible_patron!
    authenticate!
    return if eligible_patron?

    raise Error::ForbiddenError, 'This page is restricted to active UC Berkeley faculty, staff, and students.'
  end

  def require_active_loan!
    require_eligible_patron!

    raise Error::ForbiddenError, LendingItem::MSG_NOT_CHECKED_OUT unless active_loan
  end

  def ensure_lending_items!
    LendingItemLoan.overdue.find_each(&:return!)
    LendingItem.scan_for_new_items!
    @lending_items = LendingItem.order(sort_column + ' ' + sort_direction)
  end

  def ensure_lending_item!
    @lending_item ||= LendingItem.find_by(directory: directory)
  end

  def ensure_lending_item_loan!
    require_eligible_patron!

    @lending_item_loan = existing_loan || LendingItemLoan.new(**loan_args)
  end

end
# rubocop:enable Metrics/ClassLength
