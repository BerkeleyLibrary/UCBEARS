// Entry point for the build script in your package.json

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
