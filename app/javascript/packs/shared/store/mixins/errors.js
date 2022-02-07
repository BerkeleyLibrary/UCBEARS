// NOTE: we implement this as a mixin rather than a
//       VueX module because we don't want components
//       to have to deal with the implementation details
export default {
  strict: true,
  state: () => ({ errors: [] }),
  mutations: () => ({
    setErrors (state, errors) {
      state.errors = errors
    },
    clearErrors (state) {
      state.errors = null
    },
    handleError (state, error) {
      state.errors = unpackErrorResponse(error)
    }
  })
}

function unpackErrorResponse (error) {
  const railsErrors = error?.response?.data
  return railsErrors ? flattenRailsErrors(railsErrors) : []
}

function flattenRailsErrors (railsErrors) {
  return Object.entries(railsErrors)
    .flatMap(([attr, errs]) => unpackAttributeErrors(attr, errs))
}

function unpackAttributeErrors (attr, errs) {
  return errs.map(msg => normalizeErrorMessage(attr, msg))
}

function normalizeErrorMessage (attr, msg) {
  return attr === 'base' ? msg : `${attr} ${msg}`
}
