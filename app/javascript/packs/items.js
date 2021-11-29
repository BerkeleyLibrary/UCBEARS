/* eslint no-console: 0 */
import Vue from 'vue'
import ItemsTable from '../packs/items/components/ItemsTable.vue'

document.addEventListener('DOMContentLoaded', () => {
  const itemsTable = new Vue({
    render: h => h(ItemsTable)
  })
  itemsTable.$mount('#items-table')

  console.log(itemsTable)
})
