<template>
  <section class="items-admin">
    <error-alerts :errors="errors" @dismissed="dismissError"/>
    <item-filter :params="queryParams" :terms="terms" @applied="submitQuery"/>
    <items-table :items="items" :terms="terms" :paging="paging" @updated="updateItem" @removed="deleteItem"/>
    <item-paging :paging="paging" @page-selected="navigateTo"/>
  </section>
</template>

<script>
import Vue from 'vue'
import itemsApi from '../api/items'
import termsApi from '../api/terms'
import ErrorAlerts from './ErrorAlerts'
import ItemFilter from './ItemFilter'
import ItemPaging from './ItemPaging'
import ItemsTable from './ItemsTable'

export default {
  components: { ItemsTable, ErrorAlerts, ItemFilter, ItemPaging },
  data: function () {
    return {
      items: null,
      terms: null,
      paging: null,
      errors: null,
      queryParams: {
        active: null,
        complete: null,
        keywords: null,
        terms: []
      }
    }
  },
  mounted: function () {
    this.getAllTerms()
    this.getAllItems()
  },
  methods: {
    getAllTerms () {
      termsApi.getAll().then(terms => { this.terms = terms })
    },
    getAllItems () {
      itemsApi.getAll().then(this.update)
    },
    submitQuery () {
      itemsApi.findItems(this.queryParams).then(this.update)
    },
    navigateTo (pageUrl) {
      itemsApi.getPage(pageUrl).then(this.update)
    },
    updateItem (item) {
      itemsApi.update(item).then(this.setItem).catch(this.handleError)
    },
    deleteItem (item) {
      itemsApi.delete(item).then(this.removeItem).catch(this.handleError)
    },
    removeItem (item) {
      Vue.delete(this.items, item.directory)
    },
    setItem (item) {
      console.log(`Setting item ${item.directory}`)
      this.items[item.directory] = item
    },
    handleError (error) {
      console.log(error)
      const errors = error?.response?.data
      if (Array.isArray(errors)) {
        this.errors = errors
      }
    },
    dismissError (index) {
      this.errors.splice(index, 1)
    },
    // TODO: something cleaner
    update ({ items, paging }) {
      this.items = items
      this.paging = paging
    }
  }
}

</script>
