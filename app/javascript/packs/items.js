/* eslint no-console: 0 */
import Vue from 'vue'
import ItemsTable from './items/components/ItemsAdmin.vue'
import axios from 'axios'

document.addEventListener('DOMContentLoaded', () => {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')
  if (csrfToken) { // this won't be present in test
    axios.defaults.headers.common['X-CSRF-Token'] = csrfToken.getAttribute('content')
  }

  const itemsTable = new Vue({
    render: h => h(ItemsTable)
  })
  itemsTable.$mount('#items-table')

  console.log(itemsTable)
})
