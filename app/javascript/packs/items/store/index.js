import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

export default new Vuex.Store({
  strict: true,
  state: {
    table: {
      items: null,
      paging: null
    },
    terms: null,
    errors: null,
    queryParams: {
      active: null,
      complete: null,
      keywords: null,
      terms: []
    }
  },
  mutations: {
    setTerms (state, terms) {
      state.terms = terms
    },
    setTable (state, table) {
      state.table = table
    },
    setErrors (state, errors) {
      state.errors = errors
    },
    setItem (state, item) {
      state.table.items[item.directory] = item
    },
    removeItem (state, item) {
      Vue.delete(state.table.items, item.directory)
    }
  }
})
