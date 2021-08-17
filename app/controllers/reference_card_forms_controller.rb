require 'time'

class ReferenceCardFormsController < ApplicationController
  before_action :init_form!

  def index
    redirect_with_params(action: :new)
  end

  # TODO: do we still need this?
  def forbidden; end

  def result; end

  # Show the request
  def show
    require_admin!
    @current_user = current_user
    @req = ReferenceCardForm.find(params[:id])
    @days_approved = @req.days_approved
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create
    validate_recaptcha!

    # Need to grab and convert the date:
    @form.pass_date = datestr_to_date(params[:reference_card_form][:pass_date]) unless params[:reference_card_form][:pass_date].blank?
    @form.pass_date_end = datestr_to_date(params[:reference_card_form][:pass_date_end]) unless params[:reference_card_form][:pass_date_end].blank?

    if @form.save
      @form.submit!
      render 'result', status: 201
    else
      flash[:danger] = @form.errors.to_a
      redirect_with_params(action: :new)
    end
  rescue Recaptcha::RecaptchaError
    flash[:danger] = t('.recaptcha')
    redirect_with_params(action: :new)
  end

  # Approve || Deny Request
  def update
    require_admin!

    @form = ReferenceCardForm.find(params[:id])
    @form.approvedeny = params[:stack_pass_][:approve_deny]
    @form.processed_by = params[:processed_by]

    if @form.approvedeny == false
      deny_reason = params[:denial_reason]
      deny_reason = params[:stack_pass_denial][:denial_reason] if deny_reason.empty?
      @form.denial_reason = deny_reason
      @form.deny!
    else
      @form.approve!
    end

    @form.save

    flash[:success] = 'Request has been successfully processed'
    redirect_to(action: :show, id: params[:id])
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

  def datestr_to_date(str)
    return unless str.split('/').length == 3

    # Try to handle mm/dd/yy:
    if (date_param = str.match(%r{^(\d+/\d+/)(\d{2})$}))
      str = date_param[1] + '20' + date_param[2]
    end

    begin
      # Try to convert the string date to a date obj:
      Date.strptime(str, '%m/%d/%Y')
    rescue ArgumentError
      # If bad argument set to nil:
    end
  end

  def form_params
    params.require(:reference_card_form).permit(:name, :email, :affiliation, :local_id, :research_desc, :pass_date, :pass_date_end)
  rescue ActionController::ParameterMissing
    {}
  end

  def init_form!
    @form = ReferenceCardForm.new
    return if form_params.empty?

    @form.attributes = form_params
    @form.validate
  end

  def validate_recaptcha!
    verify_recaptcha!(model: @form)
  end

  def require_admin!
    @user_is_admin = current_user.role?(Role.stackpass_admin)
    redirect_to login_path(url: request.fullpath) unless @user_is_admin
  end
end
