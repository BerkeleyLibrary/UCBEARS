require 'forms_helper'

describe :libstaff_edevices_loan_form, type: :request do
  it_behaves_like(
    'an authenticated form',
    form_class: LibstaffEdevicesLoanForm,
    allowed_patron_types: [Patron::Type::LIBRARY_STAFF],
    submit_path: '/forms/library-staff-devices',
    success_path: '/forms/library-staff-devices/all_checked',
    valid_form_params: {
      libstaff_edevices_loan_form: {
        borrow_check: 'checked',
        edevices_check: 'checked',
        fines_check: 'checked',
        lending_check: 'checked'
      }
    }
  )
end
