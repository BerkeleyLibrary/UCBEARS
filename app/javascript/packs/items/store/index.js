import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

export default new Vuex.Store({
  strict: true,
  state: {
    errors: null,
    terms: [],
    table: { items: null, paging: null }
  },
  mutations: {
    setTerms (state, terms) {
      state.terms = terms
    },
    setTable (state, table) {
      state.table = table
    },
    setItem (state, item) {
      state.errors = null
      state.table.items[item.directory] = item
    },
    removeItem (state, item) {
      Vue.delete(state.table.items, item.directory)
    },
    setErrors (state, errors) {
      state.errors = errors
    },
    clearErrors (state) {
      state.errors = null
    }
  }
})
