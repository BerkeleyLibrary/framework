
/**
 * Form Input Fields: if input is empty, remove is-valid class
 */
document.addEventListener('input', (event) => {
  const input = event.target

  if (input.classList.contains('form-control')) {
    if (input.value.trim() === '') {
      input.classList.remove('is-valid')
    } else {
      input.classList.add('is-valid')
    }
  }
})
