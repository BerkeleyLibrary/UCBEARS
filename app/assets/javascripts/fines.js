/* exported selectAllFines */

function selectAllFines () {
  const feeCheckboxes = document.getElementsByName('fine[payment][]')
  feeCheckboxes.forEach(fee => { fee.checked = true })
}
