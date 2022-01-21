<template>
  <section class="items-admin">
    <error-alerts v-if="hasErrors" :errors="errors" @updated="setErrors"/>
    <item-filter :params="queryParams" :terms="terms" @applied="submitQuery"/>
    <items-table :table="table" :terms="terms" @edited="patchItem" @removed="deleteItem"/>
    <item-paging :paging="table.paging" @page-selected="navigateTo"/>
  </section>
</template>

<script>
import itemsApi from '../api/items'
import termsApi from '../api/terms'
import ErrorAlerts from './ErrorAlerts'
import ItemFilter from './ItemFilter'
import ItemPaging from './ItemPaging'
import ItemsTable from './ItemsTable'
import { mapMutations, mapState } from 'vuex'
import store from '../store'

export default {
  store,
  components: { ItemsTable, ErrorAlerts, ItemFilter, ItemPaging },
  computed: {
    hasErrors () { return !!this.errors && this.errors.length > 0 },
    ...mapState(['table', 'terms', 'errors', 'queryParams'])
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
    submitQuery (queryParams) {
      itemsApi.findItems(queryParams).then(this.setTable)
    },
    navigateTo (pageUrl) {
      itemsApi.getPage(pageUrl).then(this.setTable)
    },
    patchItem ({ item, change }) {
      itemsApi.update({ ...change, url: item.url }).then(this.setItem).catch(this.handleError)
    },
    deleteItem (item) {
      itemsApi.delete(item).then(this.removeItem).catch(this.handleError)
    },
    handleError (error) {
      this.setErrors(error?.response?.data)
    },
    ...mapMutations([
      'setTerms', 'setTable', 'setItem', 'removeItem', 'setErrors', 'removeError'
    ])
  }
}

</script>
