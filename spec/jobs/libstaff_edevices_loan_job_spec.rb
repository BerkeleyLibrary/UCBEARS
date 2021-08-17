require 'jobs_helper'

describe LibstaffEdevicesLoanJob do
  it_behaves_like(
    'a patron note job',
    note_text: 'Library Staff Electronic Devices eligible',
    email_subject_failure: 'Libdevice failure email'
  )

  it_behaves_like(
    'an email job',
    email_subject_success: 'Libdevice confirmation email'
  )
end
