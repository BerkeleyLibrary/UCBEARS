class AffiliateBorrowRequestFormsController < ApplicationController
  before_action :init_form!

  def index
    redirect_with_params(action: :new)
  end

  def create
    validate_recaptcha!
    @form.submit!

    flash[:success] = t('.success', department_head_email: @form.department_head_email)
    redirect_with_params(action: :new)
  rescue Recaptcha::RecaptchaError
    flash[:danger] = t('.recaptcha')
    redirect_with_params(action: :new)
  rescue ActiveModel::ValidationError
    redirect_with_params(action: :new)
  end

  private

  def form_params
    params.require(:affiliate_borrow_request_form).permit!
  rescue ActionController::ParameterMissing
    {}
  end

  def init_form!
    @form = AffiliateBorrowRequestForm.new
    return if form_params.empty?

    @form.attributes = form_params
    @form.validate
  end

  def validate_recaptcha!
    verify_recaptcha!(model: @form)
  end
end
