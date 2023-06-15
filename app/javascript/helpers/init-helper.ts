import { Component, createApp } from "vue";
import { createPinia } from "pinia";
import axios from "axios";

export function onLoadMount(rootComponent: Component, selector: string) {
  document.addEventListener('DOMContentLoaded', () => {
    if (document.querySelector(selector)) {
      initAxiosDefaults()
      const app = createApp(rootComponent)
      app.use(createPinia())
      app.mount(selector)
    } else {
      console.log(`Can't mount component; target selector ${selector} not found`)
    }
  })
}

function initAxiosDefaults() {
  const commonHeaders = axios.defaults.headers.common;
  const csrfToken = readCSRFToken()
  if (csrfToken) { // this won't be present in test
    commonHeaders['X-CSRF-Token'] = csrfToken
  }

  commonHeaders['Accept'] = 'application/json'
}

function readCSRFToken() {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')
  if (csrfToken) {
    return csrfToken.getAttribute('content')
  }
}
