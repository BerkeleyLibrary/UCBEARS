class StudentEdevicesLoanFormsController < AuthenticatedFormController

  private

  def success_id
    :all_checked
  end

  def special_ids
    %w[blocked forbidden all_checked]
  end

  def init_form!
    @form = StudentEdevicesLoanForm.new(
      display_name: current_user.display_name,
      given_name: current_user.given_name,
      surname: current_user.surname,
      patron: current_user.primary_patron_record
    )
    @form.authorize!
    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  # Make sure only specified attributes are allowed as params
  def form_params
    params.require(:student_edevices_loan_form).permit(
      :borrow_check,
      :edevices_check,
      :fines_check,
      :lending_check
    )
  rescue ActionController::ParameterMissing
    {}
  end
end
