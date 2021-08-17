class GalcRequestFormsController < AuthenticatedFormController

  self.support_email = 'eref@library.berkeley.edu'

  private

  def success_id
    :confirmed
  end

  def special_ids
    %w[confirmed forbidden]
  end

  def init_form!
    # Instantiate new form object
    @form = GalcRequestForm.new(patron: current_user.primary_patron_record)
    # Run through all the form validators for the strict validations
    @form.authorize!
    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  # Make sure only specified attributes are allowed as params
  def form_params
    params.require(:galc_request_form).permit(
      :patron_email,
      :borrow_check,
      :fine_check
    )
  rescue ActionController::ParameterMissing
    {}
  end
end
