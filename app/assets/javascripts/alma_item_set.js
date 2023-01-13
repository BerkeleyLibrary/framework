//= require shared/stack_requests

/* global hideBlock */
/* global showBlock */
/* global disableElement */
/* global enableElement */

/* exported toggleAlmaEnvironment */
/* exported checkFormInputs */


function toggleAlmaEnvironment (env) {
  // const feeCheckboxes = document.getElementsByName('fine[payment][]')
  // feeCheckboxes.forEach(fee => { fee.checked = true })

  if (env === 'sand') {
    // display sandbox, hide production
    hideBlock('prod-drop-down')
    showBlock('sand-drop-down')
  } else {
    // display production, hide sandbox
    hideBlock('sand-drop-down')
    showBlock('prod-drop-down')
  }
}

function checkFormInputs() {
  
  note_val = document.getElementById('note_value').value
  initials_val = document.getElementById('initials').value
  
  if (note_val == '' || initials_val == '') {
    disableElement('submit-btn')
  } else {
    enableElement('submit-btn')
  }

}

function updateItemNotes (e) {
  // Here we want to submit the form to the controller...
  // Start up a spinner and listen for the response once it's done...

  // Okay... hide the form, we're submitting it
  displayView('processing-view')

  // Listen for the ajax response!
  document.body.addEventListener('ajax:success', function(event) {
    var detail = event.detail
    var data = detail[0]
    // var status = detail[1]
    // var xhr = detail[2];

    // Let the user know how many records were updated!
    document.getElementById('email_addr').innerText = data

    displayView('results-view')
  })
  
  document.body.addEventListener('ajax:error', function(event) {
    // var detail = event.detail;
    // var data = detail[0], status = detail[1], xhr = detail[2];
    displayView('errors-view')
  })

}

function displayView(view) {
  // Hide all blocks
  hideBlock('form-view')
  hideBlock('processing-view')
  hideBlock('results-view')
  hideBlock('errors-view')

  showBlock(view)
}



// Listen for the submit button!
$(document).ready(function () {
  
  const submitButton = $('#submit-btn')
  const envRadioProd = $('#alma_env_production')
  const envRadioSand = $('#alma_env_sandbox')

  const notesInput = $('#note_value')
  const initialsInput = $('#initials')

  disableElement('submit-btn')

  // Hide the sandbox drop down on inital load
  hideBlock('sand-drop-down')
  
  // And only show the form view initally
  displayView('form-view')

  // document.getElementById('element_id').onchange = function() {
  //   // your logic
  // };

  // Because of the JS hack job I'm doing here I need to check
  // values to enable the submit button only if all fields are
  // populated. Probably much better way of doing this.
  // notesInput.keypress((e) => {checkFormInputs()})
  // initialsInput.keypress((e) => {checkFormInputs()})

  
  // Listen for the environment radios
  envRadioProd.click((e) => {toggleAlmaEnvironment('prod')})
  envRadioSand.click((e) => {toggleAlmaEnvironment('sand')})

  // And we'll handle the form submission via JS
  submitButton.click((e) => {updateItemNotes(e)})
})

