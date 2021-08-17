/* exported showBlock */
/* exported hideBlock */

/* exported disableElement */
/* exported enableElement */

/* exported formReset */

/* exported checkStackPassInputs */

/**
 * Show a block-level element by setting display: block
 */
function showBlock (id) {
  document.getElementById(id).style.display = 'block'
}

/**
 * Hide a block-level element by setting display: none
 */
function hideBlock (id) {
  document.getElementById(id).style.display = 'none'
}

/**
 * Disable an element - such as a button
 */
function disableElement (id) {
  const elem = document.getElementById(id)
  elem && (elem.disabled = true)
}

/**
 * Enable an element - such as a button
 */
function enableElement (id) {
  const elem = document.getElementById(id)
  elem && (elem.disabled = false)
}

/**
 * Custom Form Reset function
 * To use add to the if/else if block your form
 * with a list of your elements and how they should be reset
 */
function formReset (form) {
  if (form === 'stack-pass') {
    document.getElementById('stack_pass_form_name').value = ''
    document.getElementById('stack_pass_form_email').value = ''
    document.getElementById('stack_pass_form_phone').value = ''
    document.getElementById('stack_pass_form_main_stack_no').checked = false
    document.getElementById('stack_pass_form_main_stack_yes').checked = false
    hideBlock('main_stack_warn')
    document.getElementById('stack_pass_form_pass_date').value = ''
    document.getElementById('stack_pass_form_local_id').value = ''
  } else if (form === 'reference-card') {
    document.getElementById('reference_card_form_name').value = ''
    document.getElementById('reference_card_form_email').value = ''
    document.getElementById('reference_card_form_affiliation').value = ''
    document.getElementById('reference_card_form_research_desc').value = ''
    document.getElementById('reference_card_form_local_id').value = ''
    document.getElementById('reference_card_form_pass_date').value = ''
    document.getElementById('reference_card_form_pass_date_end').value = ''
  }
}

// noinspection JSUnusedGlobalSymbols
/**
 * Stack Pass approve/request page:
 * Control the submit button disable/enable
 */
function checkStackPassInputs () {
  // Approve/Deny Radio Buttons:
  const radioApprove = document.getElementById('stack_pass_approve').checked
  const radioDeny = document.getElementById('stack_pass_deny').checked

  // Denial Reason Drop Down/Select:
  const denialReasonSelected = document.getElementById('stack_pass_denial_denial_reason').value

  // Denial Reason Text Box (for "Other")
  const denialReasonOther = document.getElementById('denial_reason').value

  if (radioApprove) {
    // Approve radio button selected: Enable Submit (hide deny options)
    enableElement('process_btn')
    hideBlock('stack_pass_denial_denial_reason')
    hideBlock('other_denial')
  } else if (radioDeny) {
    // Deny radio button selected: Show deny options
    showBlock('stack_pass_denial_denial_reason')

    if (denialReasonSelected === '') {
      // If Denial Reason Selection is blank: disable submit!
      disableElement('process_btn')
    } else if (denialReasonSelected === 'Other') {
      // If Denial Reason Selection is Other: Show reason text box
      showBlock('other_denial')
      if (denialReasonOther === '') {
        // If Reason Text box is empty: disable submit
        disableElement('process_btn')
      } else {
        // Else: enable submit
        enableElement('process_btn')
      }
    } else {
      // If Denial Reason Selection is any other reason: enable submit and hide text box
      hideBlock('other_denial')
      enableElement('process_btn')
    }
  } else {
    // If neither radio is selected: disable submit
    disableElement('process_btn')
  }
}
