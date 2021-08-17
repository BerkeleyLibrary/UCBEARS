class ScanRequestFormsController < AuthenticatedFormController

  self.support_email = 'prntscan@lists.berkeley.edu'

  private

  def success_id
    @form.opted_in? ? :optin : :optout
  end

  def special_ids
    %w[blocked forbidden optin optout]
  end

  def init_form!
    logger.info(session[:user])

    @form = ScanRequestForm.new(
      patron: current_user.primary_patron_record,
      patron_name: current_user.display_name
    )

    @form.authorize!

    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  def form_params
    params.require(:scan_request_form).permit(:opt_in, :patron_name)
  rescue ActionController::ParameterMissing
    {}
  end
end
