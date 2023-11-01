/* exported selectAllFees */

function selectAllFees () {
  const feeCheckboxes = document.getElementsByName('fee[payment][]')
  feeCheckboxes.forEach(fee => { fee.checked = true })
}
