require 'jobs_helper'

describe ScanRequestOptInJob do
  include_context 'ssh'
  email_subject_success = 'alt-media scanning service opt-in'

  it_behaves_like(
    'a patron note job',
    note_text: 'library book scan eligible',
    email_subject_failure: 'alt-media scanning patron opt-in failure'
  )

  it_behaves_like(
    'an email job',
    email_subject_success: email_subject_success
  )
end
