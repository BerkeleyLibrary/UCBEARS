/* eslint no-console: 0 */
import Vue from 'vue'
import ItemsAdmin from './items/components/ItemsAdmin.vue'
import axios from 'axios'

document.addEventListener('DOMContentLoaded', () => {
  // TODO: find a more elegant way to only load this pack conditionally
  if (!document.getElementById('items-table')) {
    return
  }

  const csrfToken = document.querySelector('meta[name="csrf-token"]')
  if (csrfToken) { // this won't be present in test
    axios.defaults.headers.common['X-CSRF-Token'] = csrfToken.getAttribute('content')
  }

  new Vue({ render: h => h(ItemsAdmin) }).$mount('#items-table')
})
