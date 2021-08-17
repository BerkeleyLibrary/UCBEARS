require 'forms_helper'

describe :scan_request_forms, type: :request do
  it_behaves_like(
    'an authenticated form',
    form_class: ScanRequestForm,
    allowed_patron_types: [
      Patron::Type::FACULTY,
      Patron::Type::STAFF,
      Patron::Type::LIBRARY_STAFF,
      Patron::Type::MANAGER,
      Patron::Type::VISITING_SCHOLAR
    ],
    submit_path: '/forms/altmedia',
    success_path: '/forms/altmedia/optin',
    valid_form_params: {
      scan_request_form: {
        patron_name: 'Jane Doe',
        patron_email: 'jrdoe@berkeley.test',
        opt_in: 'true'
      }
    }
  )
end
