<template>
  <section id="items-admin" class="admin">
    <flash-alerts :messages="messages" @updated="setMessages"/>
    <item-filter :terms="terms" @applied="filterItems"/>
    <items-table :table="table" :terms="terms" @edited="patchItem" @removed="deleteItem"/>
    <item-paging :paging="table.paging" @page-selected="navigateTo"/>
  </section>
</template>

<script>
import FlashAlerts from '../../shared/components/FlashAlerts'
import ItemFilter from './ItemFilter'
import ItemPaging from './ItemPaging'
import ItemsTable from './ItemsTable'
import itemsApi from '../api/items'
import store from '../store'
import termsApi from '../../terms/api/terms'
import { msgSuccess } from '../../shared/store/mixins/flash'
import { mapMutations, mapState } from 'vuex'

export default {
  store,
  components: { ItemsTable, FlashAlerts, ItemFilter, ItemPaging },
  computed: {
    ...mapState(['table', 'messages', 'terms'])
  },
  mounted: function () {
    this.getAllTerms()
    this.getAllItems()
  },
  methods: {
    getAllTerms () {
      termsApi.getAll().then(this.setTerms)
    },
    getAllItems () {
      itemsApi.getAll().then(this.setTable)
    },
    filterItems (itemFilter) {
      itemsApi.findItems(itemFilter).then(this.setTable)
    },
    navigateTo (pageUrl) {
      itemsApi.getPage(pageUrl).then(this.setTable)
    },
    patchItem ({ item, change }) {
      console.log('patchItem(' + JSON.stringify(change) + ')')
      itemsApi.update({ ...change, url: item.url }).then(this.itemPatched).catch(this.handleError)
    },
    deleteItem (item) {
      itemsApi.delete(item).then(this.itemDeleted).catch(this.handleError)
    },
    itemPatched (item) {
      this.clearMessages()
      this.setItem(item)
    },
    itemDeleted (item) {
      this.removeItem(item)
      this.setMessage(msgSuccess('Item deleted.'))
    },
    ...mapMutations([
      'setTable', 'setItem', 'removeItem', 'setTerms', 'setMessages', 'clearMessages', 'setMessage', 'handleError'
    ])
  }
}

</script>
