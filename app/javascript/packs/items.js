/* eslint no-console: 0 */
import Vue from 'vue'
import ItemsTable from '../packs/items/components/ItemsTable.vue'
import axios from 'axios'

document.addEventListener('DOMContentLoaded', () => {
  axios.defaults.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

  const itemsTable = new Vue({
    render: h => h(ItemsTable)
  })
  itemsTable.$mount('#items-table')

  console.log(itemsTable)
})
