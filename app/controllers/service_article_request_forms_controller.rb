class ServiceArticleRequestFormsController < AuthenticatedFormController

  self.support_email = 'baker@library.berkeley.edu'

  private

  def success_id
    :confirmed
  end

  def special_ids
    %w[ineligible confirmed forbidden required student]
  end

  def init_form!
    @form = ServiceArticleRequestForm.new(
      display_name: current_user.display_name,
      patron: current_user.primary_patron_record
    )
    @form.authorize!
    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  # Make sure only specified attributes are allowed as params
  # rubocop:disable Metrics/MethodLength
  def form_params
    params.require(:service_article_request_form).permit(
      :display_name,
      :patron_email,
      :pub_title,
      :pub_location,
      :issn,
      :vol,
      :article_title,
      :author,
      :pages,
      :citation,
      :pub_notes
    )
  rescue ActionController::ParameterMissing
    {}
  end
  # rubocop:enable Metrics/MethodLength
end
