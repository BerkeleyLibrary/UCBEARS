require 'jobs_helper'

describe DoemoffStudyRoomUseJob do
  it_behaves_like(
    'a patron note job',
    note_text: 'Doe/Moffitt study room eligible',
    email_subject_failure: 'Doemoff room failure email'
  )

  it_behaves_like(
    'an email job',
    email_subject_success: 'Doemoff room confirmation email'
  )
end
