/* exported flashAlerts */

/**
 * Hacking Rails flash alerts -- see ApplicationHelper#alerts
 * for where/how server-side alerts are rendered
 */
class FlashAlerts {
  clear () {
    const alerts = this._alerts()
    if (alerts) {
      let child
      while ((child = alerts.firstChild)) {
        child.remove()
      }
    }
  }

  error (msg) {
    this.addAlert(msg, 'error')
  }

  success (msg) {
    this.addAlert(msg, 'success')
  }

  raw (msg) {
    this.addAlert(msg)
  }

  addAlert (msg, lvl) {
    const alerts = this._alerts()
    if (!alerts) {
      console.log(`Alerts container not present; can't add alert message "${msg}"`)
      return
    }
    const alert = document.createElement('div')
    if (lvl) {
      const alertClass = this._alertClass(lvl)
      alert.className = `alert ${alertClass}`
    }
    alert.append(msg)
    return alerts.appendChild(alert)
  }

  _alerts () {
    return document.querySelector('div.alerts')
  }

  _alertClass (lvl) {
    switch (lvl) {
      case 'success':
        return 'alert-success'
      case 'error':
        return 'alert-danger'
      case 'warning':
        return 'alert-warning'
      default:
        return 'alert-info'
    }
  }
}

// noinspection JSUnusedGlobalSymbols
const flashAlerts = new FlashAlerts()
