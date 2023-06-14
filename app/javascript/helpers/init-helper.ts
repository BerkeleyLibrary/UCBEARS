import { Component, createApp } from "vue";
import { createPinia } from "pinia";
import axios from "axios";

export function onLoadMount(rootComponent: Component, selector: string) {
  document.addEventListener('DOMContentLoaded', () => {
    initAxiosDefaults()
    const app = createApp(rootComponent)
    app.use(createPinia())
    app.mount(selector)
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
