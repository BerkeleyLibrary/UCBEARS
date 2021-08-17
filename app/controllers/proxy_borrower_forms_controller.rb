require 'time'

# class ProxyBorrowerFormsController < ApplicationController
class ProxyBorrowerFormsController < AuthenticatedFormController
  # Simple page where you can select which form you wish to access
  def index
    # I think I want to get the users role now... if they're in the DB
    # then I'll want to pass that info so they have the
    # admin link...otherwise, NO admin link!
    @user_is_admin = current_user.role?(Role.proxyborrow_admin)
  end

  def dsp_form
    # wisks us away to Disabled Student Program Form (views/proxy_borrower_forms/dsp_form)
    @request_form = ProxyBorrowerRequests.new
    @current_user = current_user
  end

  def faculty_form
    # wisks us away to Faculty Form
    if current_user.ucb_faculty?
      @request_form = ProxyBorrowerRequests.new
      @current_user = current_user
    else
      redirect_to forms_proxy_borrower_forbidden_path
    end
  end

  # TODO: do we still need this?
  def forbidden; end

  # Processes a request from DSP form: (eventually dry this up)
  def process_dsp_request
    @request_form = process_params(params)

    if @request_form.save
      # Sends an email to the user with instructions:
      @request_form.submit!
      render 'result', status: 201
    else
      @current_user = current_user
      render 'dsp_form'
    end
  end

  # Processes a request from faculty form:
  def process_faculty_request
    @request_form = process_params(params)

    if @request_form.save
      # Sends an email to the user with instructions:
      @request_form.submit!
      render 'result', status: 201
    else
      # Failed to save - rerender the faculty form:
      @current_user = current_user
      render 'faculty_form'
    end
  end

  def result
    # Hunkydory, we saved a request to the DB, let's let the user know!
  end

  private

  def init_form!; end

  REQUEST_PARAMS = %w[
    faculty_name
    department
    faculty_id
    user_email
    student_name
    student_dsp
    research_last
    research_first
    research_middle
    dsp_rep
  ].freeze

  def process_params(params)
    ProxyBorrowerRequests.new.tap do |request|
      REQUEST_PARAMS.each { |k| request[k] = params[k] }
      request['renewal'] = params['renewal'].to_i
      request['date_term'] = convert_date_param(params['term'])
    end
  end

  def convert_date_param(date_param)
    return unless date_param

    Date.strptime(date_param, '%m/%d/%y')
  rescue Date::Error
    nil
  end

end
