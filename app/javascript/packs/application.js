import Rails from '@rails/ujs'

Rails.start()

window.addEventListener('load', () => {
  const navMenuCheckbox = document.getElementById('nav-menu')
  if (!navMenuCheckbox) {
    console.log('navMenuCheckbox not found')
    return
  }
  navMenuCheckbox.addEventListener('keydown', (e) => {
    if (e.code === 'Enter') {
      navMenuCheckbox.checked = !navMenuCheckbox.checked
    }
  })
})
