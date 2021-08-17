require 'forms_helper'

describe :doemoff_study_room_use_forms, type: :request do
  it_behaves_like(
    'an authenticated form',
    form_class: DoemoffStudyRoomUseForm,
    allowed_patron_types: [
      Patron::Type::UNDERGRAD,
      Patron::Type::UNDERGRAD_SLE,
      Patron::Type::GRAD_STUDENT,
      Patron::Type::FACULTY,
      Patron::Type::MANAGER,
      Patron::Type::LIBRARY_STAFF,
      Patron::Type::STAFF,
      Patron::Type::POST_DOC,
      Patron::Type::VISITING_SCHOLAR
    ],
    submit_path: '/forms/doemoff-study-room-use',
    success_path: '/forms/doemoff-study-room-use/all_checked',
    valid_form_params: {
      doemoff_study_room_use_form: {
        borrow_check: 'checked',
        roomUse_check: 'checked',
        fines_check: 'checked'
      }
    }
  )
end
