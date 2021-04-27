/**
 * formshowhide
 * Toggles the renewal instructions for the 2 
 * proxy borrower forms.
 */
function formshowhide(id) {
  if (id === "not_renewal") {
    document.getElementById('not_renewalf').style.display = "block";
    document.getElementById('renewalf').style.display = "none";
  } else {
    document.getElementById('not_renewalf').style.display = "none";
    document.getElementById('renewalf').style.display = "block";
  }
}

/**
 * Display or hide an element
 */
function toggleBlock(id, display) {
  if (display) {
    document.getElementById(id).style.display = "block";
  } else {
    document.getElementById(id).style.display = "none";
  }
}

/**
 * Disable or enable an element - such as a button
 */
function setDisabled(id, disable) {
  document.getElementById(id).disabled = !!disable;
}

/**
 * Disable an element - such as a button
 */
function disableElement(id) {
    let elem = document.getElementById(id);
    elem && (elem.disabled = true);
}

/**
 * Enable an element - such as a button
 */
function enableElement(id) {
    let elem = document.getElementById(id);
    elem && (elem.disabled = false);
}

/**
 * hardReset
 * Resets the Proxy Borrower Card DSP and Faculty forms
 * Needed in the event someone submits bad data and we
 * reload the form with the previous results; a plain
 * jane html 'reset' button will reset to the values
 * returned to the form.
 */
function hardReset() {
  // These fields are all the same in both DSP and Faculty forms:
  document.getElementById("research_last").value = "";
  document.getElementById("research_first").value = "";
  document.getElementById("research_middle").value = "";
  document.getElementById("term").value = "";
  document.getElementById("renewal_1").checked = false;
  document.getElementById("renewal_0").checked = true;

  // In case user changed the renewal to 'yes', clear it:
  formshowhide("not_renewal");

  // DSP Form only:
  if (document.getElementById("dsp_rep")) {
    document.getElementById("dsp_rep").value = "";
  }
}

/**
 * Custom Form Reset function
 * To use add to the if/else if block your form
 * with a list of your elements and how they should be reset
 */
function formReset(form) {
  if (form === 'stack-pass') {
    document.getElementById("stack_pass_form_name").value = "";
    document.getElementById("stack_pass_form_email").value = "";
    document.getElementById("stack_pass_form_phone").value = "";
    document.getElementById("stack_pass_form_main_stack_no").checked = false;
    document.getElementById("stack_pass_form_main_stack_yes").checked = false;
    toggleBlock("main_stack_warn", false);
    document.getElementById("stack_pass_form_pass_date").value = "";
    document.getElementById("stack_pass_form_local_id").value = "";
  } else if (form === 'reference-card') {
    document.getElementById("reference_card_form_name").value = "";
    document.getElementById("reference_card_form_email").value = "";
    document.getElementById("reference_card_form_affiliation").value = "";
    document.getElementById("reference_card_form_research_desc").value = "";
    document.getElementById("reference_card_form_local_id").value = "";
    document.getElementById("reference_card_form_pass_date").value = "";
    document.getElementById("reference_card_form_pass_date_end").value = "";
  }

}

// Stack Pass approve/request page:
// Control the submit button disable/enable
function sp_proccess_check() {
  // Approve/Deny Radio Buttons:
  radio_approve = document.getElementById("stack_pass_approve").checked;
  radio_deny = document.getElementById("stack_pass_deny").checked;

  // Denial REason Drop Down/Select:
  denial_selection = document.getElementById("stack_pass_denial_denial_reason").value;

  // Denial Reason Text Box (for "Other")
  denial_reason = document.getElementById("denial_reason").value;

  if (radio_approve) {
    // Approve radio button selected: Enable Submit (hide deny options)
    enableElement("process_btn");
    toggleBlock("stack_pass_denial_denial_reason", false)
    toggleBlock("other_denial", false);
  } else if (radio_deny) {
    // Deny radio button selected: Show deny options
    toggleBlock("stack_pass_denial_denial_reason", true)

    if (denial_selection === '') {
      // If Denial Reason Selection is blank: disable submit!
      disableElement("process_btn");
    } else if (denial_selection === 'Other') {
      // If Denial Reason Selection is Other: Show reason text box
      toggleBlock("other_denial", true);
      if (denial_reason === '') {
        // If Reason Text box is empty: disable submit
        disableElement("process_btn");
      } else {
        // Else: enable submit
        enableElement("process_btn");
      }
    } else {
      // If Denial Reason Selection is any other reason: enable submit and hide text box
      toggleBlock("other_denial", false);
      enableElement("process_btn");
    }
  } else {
    // If neither radio is selected: disable submit
    disableElement("process_btn");
  }

}
