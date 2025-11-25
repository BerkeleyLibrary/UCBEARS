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
      state.table = {
        ...table,
        items: Array.isArray(table.items)
          ? table.items
          : Object.values(table.items || {})
      }
    },
    setItem (state, item) {
      const index = state.table.items.findIndex(i => i.directory === item.directory)
      if (index !== -1) {
        Vue.set(state.table.items, index, item)
      }
    },
    removeItem (state, item) {
      const index = state.table.items.findIndex(i => i.directory === item.directory)
      if (index !== -1) {
        state.table.items.splice(index, 1)
      }
    }
  }
})
