import Vue from 'vue'
import Vuex from 'vuex'

// NOTE: We implement these as mixins rather than as
//       VueX modules so we can have modularity &
//       reusability without making our client components
//       care about the implementation details
import terms from '../../shared/store/mixins/terms'
import flash from '../../shared/store/mixins/flash'

Vue.use(Vuex)

export default new Vuex.Store({
  strict: true,
  state: {
    ...terms.state(),
    ...flash.state(),
    termFilter: { future: null, past: null, current: null }
  },
  mutations: {
    ...terms.mutations(),
    ...flash.mutations(),
    setTerm (state, term) {
      state.messages = null

      const terms = state.terms
      const termIndex = terms.findIndex(t => t.id === term.id)
      if (termIndex >= 0) {
        terms.splice(termIndex, 1, term)
      } else {
        terms.push(term)
      }
    },
    removeTerm (state, term) {
      state.messages = null

      const terms = state.terms
      const termIndex = terms.findIndex(t => t.id === term.id)
      if (termIndex >= 0) {
        terms.splice(termIndex, 1)
      }
    }
  }
})
