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
    table: { items: null, paging: null }
  },
  mutations: {
    ...terms.mutations(),
    ...flash.mutations(),
    setTable (state, table) {
      state.table = table
    },
    setItem (state, item) {
      state.messages = null
      state.table.items[item.directory] = item
    },
    removeItem (state, item) {
      Vue.delete(state.table.items, item.directory)
    }
  }
})
