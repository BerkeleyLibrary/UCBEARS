<template>
  <section id="terms-admin" class="admin">
    <error-alerts :errors="errors" @updated="setErrors"/>
    <term-filter @applied="submitQuery"/>
    <table v-if="terms">
      <thead>
        <tr>
          <th>Name</th>
          <th>Start date</th>
          <th>End date</th>
          <th>Updated</th>
          <th>Items</th>
          <th>Delete</th>
        </tr>
      </thead>
      <tbody>
        <term-row
          v-for="term in terms"
          :key="term.id"
          :term="term"
          @edited="edit(term)($event)"
          @removed="deleteTerm(term)"
        />
      </tbody>
      <add-term-widget/>
    </table>
  </section>
</template>

<script>
import ErrorAlerts from '../../shared/components/ErrorAlerts'
import TermFilter from './TermFilter'
import TermRow from './TermRow'
import AddTermWidget from './AddTermWidget'
import store from '../store'
import termsApi from '../api/terms'
import { mapMutations, mapState } from 'vuex'

function confirmDelete (term) {
  if (term.item_count === 0) {
    return true
  }
  let itemsStr = 'item'
  if (term.item_count > 1) {
    itemsStr = `${itemsStr}s`
  }
  const msg = `Term ${term.name} has ${term.item_count} ${itemsStr}. Really delete it?`
  return window.confirm(msg)
}

export default {
  store,
  components: { ErrorAlerts, TermFilter, TermRow, AddTermWidget },
  computed: {
    ...mapState(['terms', 'errors'])
  },
  mounted: function () {
    this.getAllTerms()
  },
  methods: {
    getAllTerms () {
      termsApi.getAll().then(this.setTerms)
    },
    edit (term) {
      return (change) => {
        termsApi.update({ ...change, url: term.url }).then(this.setTerm).catch(this.handleError)
      }
    },
    deleteTerm (term) {
      if (confirmDelete(term)) {
        termsApi.delete(term).then(this.removeTerm).catch(this.handleError)
      }
    },
    submitQuery (termFilter) {
      termsApi.findTerms(termFilter).then(this.setTerms).catch(this.handleError)
    },
    handleError (error) {
      this.setErrors(error?.response?.data)
    },
    ...mapMutations([
      'setTerms', 'setTerm', 'removeTerm', 'setErrors', 'clearErrors'
    ])
  }
}
</script>
