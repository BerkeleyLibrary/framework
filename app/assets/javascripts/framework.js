/**
 * formshowhide
 * Toggles the renewal instructions for the 2 
 * proxy borrower forms.
 */
function formshowhide(id) {
  if (id == "not_renewal") {
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
function toggleDisable(id, disable) {
  if (disable) {
    document.getElementById(id).disabled = true;
  } else {
    document.getElementById(id).disabled = false;
  }
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

function handleDenialSelect() {
  selection = document.getElementById("stack_pass_denial_denial_reason").value;
  if (selection === 'Other') {
    document.getElementById("denial_reason").value = '';
    toggleDisable("process_btn", false);
    toggleBlock("other_denial", true);
  } else {
    toggleBlock("other_denial", false);
    toggleDisable("process_btn", false);
    document.getElementById("denial_reason").value = selection;
  }
}
