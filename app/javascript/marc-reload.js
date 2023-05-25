window.addEventListener('load', () => {
  const marcReloadButton = document.getElementById('marc-reload')
  if (!marcReloadButton) {
    console.log('marcReloadButton not found')
    return
  }
  const confirmMsg = marcReloadButton.dataset.confirm
  if (!confirmMsg) {
    console.log('confirmMsg not found')
    return
  }
  const marcReloadForm = marcReloadButton.closest('form')
  if (!marcReloadForm) {
    console.log('marcReloadForm not found')
    return
  }
  marcReloadForm.addEventListener('submit', (e) => {
    const confirmed = window.confirm(confirmMsg)
    if (!confirmed) {
      e.preventDefault()
    }
  })
})
