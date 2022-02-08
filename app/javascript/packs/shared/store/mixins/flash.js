// NOTE: we implement this as a mixin rather than a
//       VueX module because we don't want components
//       to have to deal with the implementation details
export default {
  strict: true,
  state: () => ({ messages: [] }),
  mutations: () => ({
    setMessages (state, messages) {
      state.messages = messages
    },
    clearMessages (state) {
      state.messages = []
    },
    handleError (state, error) {
      state.messages = unpackErrorResponse(error)
    }
  })
}

function unpackErrorResponse (error) {
  const railsMessages = error?.response?.data
  return railsMessages ? flattenRailsMessages(railsMessages) : []
}

function flattenRailsMessages (railsMessages) {
  return Object.entries(railsMessages)
    .flatMap(([attr, errs]) => unpackAttributeMessages(attr, errs))
}

function unpackAttributeMessages (attr, errs) {
  return errs.map(msg => normalizeErrorMessage(attr, msg))
}

function normalizeErrorMessage (attr, msg) {
  return attr === 'base' ? msg : `${attr} ${msg}`
}
