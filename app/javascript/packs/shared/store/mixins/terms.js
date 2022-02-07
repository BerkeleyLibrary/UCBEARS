// NOTE: we implement this as a mixin rather than a
//       VueX module because we don't want components
//       to have to deal with the implementation details
export default {
  state: () => ({ terms: [] }),
  mutations: () => ({
    setTerms (state, terms) {
      state.terms = terms
    }
  })
}
