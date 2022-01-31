import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

export default new Vuex.Store({
  strict: true,
  state: {
    errors: null,
    termFilter: { future: null, past: null, current: null },
    terms: []
  },
  mutations: {
    setTerms (state, terms) {
      state.terms = terms
    },
    setTerm (state, term) {
      state.errors = null

      const terms = state.terms
      const termIndex = terms.findIndex(t => t.id === term.id)
      if (termIndex >= 0) {
        terms.splice(termIndex, 1, term)
      } else {
        terms.push(term)
      }
    },
    removeTerm (state, term) {
      state.errors = null

      const terms = state.terms
      const termIndex = terms.findIndex(t => t.id === term.id)
      if (termIndex >= 0) {
        terms.splice(termIndex, 1)
      }
    },
    setErrors (state, errors) {
      console.log(`setErrors(${JSON.stringify(errors)})`)
      state.errors = errors
    },
    clearErrors (state) {
      state.errors = null
    }
  }
})
