//= require shared/stack_requests

/* global hideBlock */
/* global showBlock */

/* exported hardReset */

/**
 * hardReset
 * Resets the Proxy Borrower Card DSP and Faculty forms
 * Needed in the event someone submits bad data and we
 * reload the form with the previous results; a plain
 * jane html 'reset' button will reset to the values
 * returned to the form.
 */
function hardReset () {
  // These fields are all the same in both DSP and Faculty forms:
  document.getElementById('research_last').value = ''
  document.getElementById('research_first').value = ''
  document.getElementById('research_middle').value = ''
  document.getElementById('term').value = ''
  document.getElementById('renewal_1').checked = false
  document.getElementById('renewal_0').checked = true

  // In case user changed the renewal to 'yes', clear it:
  setProxyBorrowerRenewal('not_renewal')

  // DSP Form only:
  if (document.getElementById('dsp_rep')) {
    document.getElementById('dsp_rep').value = ''
  }
}

/**
 * Toggles the renewal instructions for the 2
 * proxy borrower forms.
 */
function setProxyBorrowerRenewal (id) {
  if (id === 'not_renewal') {
    showBlock('not_renewalf')
    hideBlock('renewalf')
  } else {
    showBlock('renewalf')
    hideBlock('not_renewalf')
  }
}
