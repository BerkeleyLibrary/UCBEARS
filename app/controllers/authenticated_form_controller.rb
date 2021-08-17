# Superclass of form controllers that require authentication
class AuthenticatedFormController < ApplicationController

  before_action :authenticate!

  # noinspection RailsParamDefResolve
  before_action :init_form!

  def index
    # noinspection RailsParamDefResolve
    redirect_to action: :new
  end

  def create
    @form.submit!
    redirect_to action: :show, id: success_id
  rescue ActiveModel::ValidationError => e
    Rails.logger.error(e)

    flash[:danger] ||= []
    @form.errors.full_messages.each { |msg| flash[:danger] << msg }
    redirect_with_params(action: :new)
  end

  def show
    if special_ids.include?(params[:id])
      render params[:id]
    else
      # noinspection RailsParamDefResolve
      redirect_to action: :new
    end
  end

end
