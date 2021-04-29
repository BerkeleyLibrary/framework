/* exported showBlock */
/* exported hideBlock */
/* exported disableElement */
/* exported enableElement */

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
