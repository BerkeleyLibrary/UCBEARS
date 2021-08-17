require 'jobs_helper'

describe ScanRequestOptOutJob do
  email_subject_success = 'alt-media scanning service opt-out'

  it_behaves_like(
    'an email job',
    email_subject_success: email_subject_success,
    confirm_cc: %w[prntscan@lists.berkeley.edu baker@library.berkeley.edu]
  )
end
