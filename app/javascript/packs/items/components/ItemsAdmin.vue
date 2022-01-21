<template>
  <section class="items-admin">
    <error-alerts :errors="errors" @dismissed="dismissError"/>
    <item-filter :params="queryParams" :terms="terms" @applied="submitQuery"/>
    <items-table :items="items" :terms="terms" :paging="paging" @updated="setItem" @removed="removeItem"/>
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
    removeItem (item) {
      console.log(`Item ${item.directory} removed`)
      Vue.delete(this.items, item.directory)
    },
    setItem (item) {
      console.log(`Setting item ${item.directory}`)
      this.items[item.directory] = item
    },
    // TODO: use this
    setErrors (errors) {
      this.errors = errors
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
