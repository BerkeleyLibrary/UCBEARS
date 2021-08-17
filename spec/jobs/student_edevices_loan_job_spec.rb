require 'jobs_helper'

describe StudentEdevicesLoanJob do
  it_behaves_like(
    'a patron note job',
    note_text: 'Student Electronic Devices eligible',
    email_subject_failure: 'Student Electronic Devices Loan error'
  )

  it_behaves_like(
    'an email job',
    email_subject_success: 'Student Electronic Devices Loan confirmation'
  )
end
