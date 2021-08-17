require 'jobs_helper'

describe GalcRequestJob do
  it_behaves_like(
    'a patron note job',
    note_text: 'GALC eligible',
    email_subject_failure: 'Galc failure email'
  )

  it_behaves_like(
    'an email job',
    email_subject_success: 'GALC confirmation email'
  )
end
