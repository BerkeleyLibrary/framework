/* exported formReset */
/* exported hardReset */
/* exported checkStackPassInputs */

/* global hideBlock */
/* global showBlock */
/* global enableElement */
/* global disableElement */

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
