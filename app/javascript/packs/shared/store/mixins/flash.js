// noinspection JSUnusedGlobalSymbols

// ------------------------------------------------------------
// Store mixin

/**
 * Store mixin for flash messages.
 *
 * NOTE: we implement this as a mixin rather than a
 * VueX module because we don't want components
 * to have to deal with the implementation details.
 */
export default {
  strict: true,
  state: () => ({ messages: [] }),
  mutations: () => ({
    setMessages (state, messages) {
      console.log(`setMessages(${messages})`)
      state.messages = messages
      console.log(state.messages)
    },
    clearMessages (state) {
      console.log('clearMessages()')
      state.messages = []
      console.log(state.messages)
    },
    setMessage (state, { level, text }) {
      console.log(`setMessage(${level}, ${text})`)
      state.messages = [newMessage(level, text)]
      console.log(state.messages)
    },
    handleError (state, error) {
      console.log(`handleError(${error})`)
      state.messages = unpackErrorResponse(error)
      console.log(state.messages)
    }
  })
}

// ------------------------------------------------------------
// Exported

export function msgSuccess (text) {
  return newMessage(lvlSuccess, text)
}

// ------------------------------------------------------------
// Unexported

const lvlError = 'error'
const lvlSuccess = 'success'

function newMessage (level, text) {
  return { level: level, text: text }
}

function unpackErrorResponse (axiosError) {
  const error = axiosError?.response?.data?.error
  if (!error) {
    return []
  }

  const messages = []
  if (error.message) {
    messages.push(newMessage(lvlError, error.message))
  }
  if (error.errors) {
    for (const err of error.errors) {
      if (err.message) {
        messages.push(newMessage(lvlError, err.message))
      }
    }
  }
  return messages
}
