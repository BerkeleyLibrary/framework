
/* $(function() {
  $('a#show_police_notified').click(function(event){
    event.preventDefault();
    $('div#police_notified').toggle();
  });
}); */

function showBlock (id) {
  document.getElementById(id).style.display = 'block'
}

/**
 * Hide a block-level element by setting display: none
 */
function hideBlock (id) {
  document.getElementById(id).style.display = 'none'
}

function formReset () {
  hideBlock('police_info')
  //hideBlock('subject_description_1')
  //hideBlock('subject_description_2')

  /* document.getElementById('stack_pass_form_name').value = ''
  document.getElementById('stack_pass_form_email').value = ''
  document.getElementById('stack_pass_form_phone').value = ''
  document.getElementById('stack_pass_form_main_stack_no').checked = false
  document.getElementById('stack_pass_form_main_stack_yes').checked = false
  hideBlock('police_info')
  document.getElementById('stack_pass_form_pass_date').value = ''
  document.getElementById('stack_pass_form_local_id').value = '' */
}

   
function showSection(section_toggle, section) {
  $("a#" + section_toggle).click(function(event){
    event.preventDefault();
    $('div#' + section).toggle();
  });
};
