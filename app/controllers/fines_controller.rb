require 'jwt'

class FinesController < ApplicationController
  # This will be needed for transaction_complete since Paypal will hit that
  protect_from_forgery with: :null_session

  self.support_email = 'helpbox@library.berkeley.edu'

  def index
    @jwt = params.require(:jwt)
    decoded_token = JWT.decode @jwt, nil, false
    @alma_id = decoded_token.first['userName']
    @fines = FinesPayment.new(alma_id: @alma_id)
  rescue JWT::DecodeError
    redirect_to(action: :transaction_error)
  end

  def payment
    if params[:fine].present?
      @fines = FinesPayment.new(alma_id: params[:alma_id], fine_ids: params[:fine][:payment])
    else
      flash[:danger] = 'Please select at least one fee.'
      redirect_with_params(action: :index)
    end
  end

  def transaction_fail
    log_error('TRANSACTION_FAIL', params)
  end

  def transaction_error
    log_error('TRANSACTION_ERROR', params)
  end

  def transaction_complete
    log_info('TRANSACTION_COMPLETE', params)
    render(plain: 'Failed', status: 500) && return unless params['RESULT'] == '0'
    @fines = FinesPayment.new(alma_id: params[:USER1], fine_ids: params[:USER2])
    @fines.pp_ref_number = params[:PNREF]
    @fines.credit
    render json: { status: 'silent post received' }
  end

  private

  # def log_error(src, p)
  def log_error(e, p = nil)
    logger.error("FINES-#{e}: ALMA_ID: #{p[:USER]}, PP_ID: #{p[:PNREF]}, FEE_IDS: #{p[:USER2]}, AMT: #{p[:AMT]}, RESPMSG: #{p[:RESPMSG]}") if p
  end

  def log_info(src, p)
    logger.info("FINES-#{src}: ALMA_ID: #{p[:USER1]}, PP_ID: #{p[:PNREF]}, FEE_IDS: #{p[:USER2]}, AMT: #{p[:AMT]}, RESPMSG: #{p[:RESPMSG]}")
  end

end
