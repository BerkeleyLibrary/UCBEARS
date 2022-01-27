<template>
  <section id="items-admin" class="admin">
    <error-alerts v-if="hasErrors" :errors="errors" @updated="setErrors"/>
    <item-filter :params="queryParams" :terms="terms" @applied="submitQuery"/>
    <items-table :table="table" :terms="terms" @edited="patchItem" @removed="deleteItem"/>
    <item-paging :paging="table.paging" @page-selected="navigateTo"/>
  </section>
</template>

<script>
import ErrorAlerts from '../../shared/components/ErrorAlerts'
import ItemFilter from './ItemFilter'
import ItemPaging from './ItemPaging'
import ItemsTable from './ItemsTable'
import itemsApi from '../api/items'
import store from '../store'
import termsApi from '../../terms/api/terms'
import { mapMutations, mapState } from 'vuex'

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
      'setTerms', 'setTable', 'setItem', 'removeItem', 'setErrors'
    ])
  }
}

</script>
