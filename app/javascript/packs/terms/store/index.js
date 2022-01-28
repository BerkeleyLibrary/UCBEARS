import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

export default new Vuex.Store({
  strict: true,
  state: {
    terms: [],
    errors: null
  },
  mutations: {
    setTerms (state, terms) {
      state.terms = terms
    },
    setTerm (state, term) {
      const terms = state.terms
      const termIndex = terms.findIndex(t => t.id === term.id)
      if (termIndex >= 0) {
        terms.splice(termIndex, 1, term)
      } else {
        terms.push(term)
      }
    },
    removeTerm (state, term) {
      const terms = state.terms
      const termIndex = terms.findIndex(t => t.id === term.id)
      if (termIndex >= 0) {
        terms.splice(termIndex, 1)
      }
    },
    setErrors (state, errors) {
      console.log(`setErrors(${JSON.stringify(errors)})`)
      state.errors = errors
    }
  }
})
