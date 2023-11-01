require 'jwt'

class FeesController < ApplicationController
  # This will be needed for transaction_complete since Paypal will hit that
  protect_from_forgery with: :null_session

  def index
    @jwt = params.require(:jwt)
    decoded_token = JWT.decode @jwt, nil, false
    @alma_id = decoded_token.first['userName']
    @fees = FeesPayment.new(alma_id: @alma_id)
  rescue JWT::DecodeError
    redirect_to(action: :transaction_error)
  end

  def efee
    @jwt = params.require(:jwt)
    secret = EfeesInvoice.secret
    decoded_token = JWT.decode @jwt, secret, true, { algorithm: 'HS256' }
    @alma_id = decoded_token.first['userName']
    @fees = FeesPayment.new(alma_id: @alma_id)
    render 'index'
  rescue JWT::DecodeError
    redirect_to(action: :transaction_error)
  end

  # Form to lookup patron fees
  def efees
    authorize!
  end

  # Display User Info to Lib Staff
  def lookup
    authorize!
    begin
      @user = Alma::User.find_if_exists params[:alma_id]
    rescue ActiveRecord::RecordNotFound
      flash[:danger] = "Error: No patron found with Alma ID: #{params[:alma_id]}"
      redirect_to(action: :efees)
    end
  end

  def send_invoice
    invoice = EfeesInvoice.new(params[:user_id])
    @email = invoice.email
    invoice.submit!
  end

  def payment
    if params[:fee].present?
      @fees = FeesPayment.new(alma_id: params[:alma_id], fee_ids: params[:fee][:payment])
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
    render(plain: 'Failed', status: :internal_server_error) && return unless params['RESULT'] == '0'

    @fees = FeesPayment.new(alma_id: params[:USER1], fee_ids: params[:USER2])
    @fees.pp_ref_number = params[:PNREF]
    @fees.credit
    render json: { status: 'silent post received' }
  end

  private

  def authorize!
    return if Rails.env.development?

    authenticate!
    raise Error::ForbiddenError unless current_user.alma_admin
  end

  # def log_error(src, p)
  def log_error(e, p = nil)
    logger.error("FEES-#{e}: ALMA_ID: #{p[:USER]}, PP_ID: #{p[:PNREF]}, FEE_IDS: #{p[:USER2]}, AMT: #{p[:AMT]}, RESPMSG: #{p[:RESPMSG]}") if p
  end

  def log_info(src, p)
    logger.info("FEES-#{src}: ALMA_ID: #{p[:USER1]}, PP_ID: #{p[:PNREF]}, FEE_IDS: #{p[:USER2]}, AMT: #{p[:AMT]}, RESPMSG: #{p[:RESPMSG]}")
  end

end
