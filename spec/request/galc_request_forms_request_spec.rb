require 'forms_helper'

describe :galc_request_form, type: :request do
  it_behaves_like(
    'an authenticated form',
    form_class: GalcRequestForm,
    allowed_patron_types: [
      Patron::Type::UNDERGRAD,
      Patron::Type::UNDERGRAD_SLE,
      Patron::Type::GRAD_STUDENT,
      Patron::Type::FACULTY,
      Patron::Type::MANAGER,
      Patron::Type::LIBRARY_STAFF,
      Patron::Type::STAFF
    ],
    submit_path: '/forms/galc-agreement',
    success_path: '/forms/galc-agreement/confirmed',
    valid_form_params: {
      galc_request_form: {
        borrow_check: 'checked',
        fine_check: 'checked'
      }
    }
  )
end
