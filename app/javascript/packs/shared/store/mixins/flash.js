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

function unpackErrorResponse (error) {
  const railsMessages = error?.response?.data
  return railsMessages ? flattenRailsMessages(railsMessages) : []
}

function flattenRailsMessages (railsMessages) {
  return Object.entries(railsMessages)
    .flatMap(([attr, errs]) => unpackAttributeMessages(attr, errs))
}

function unpackAttributeMessages (attr, errs) {
  console.log(`unpackAttributeMessages(${attr}, ${errs})`)
  console.log(attr)
  console.log(errs)
  return errs.map(msg => attributeErrorToMessage(attr, msg))
}

function attributeErrorToMessage (attr, err) {
  const text = normalizeAttributeErrorText(attr, err)
  return newMessage(lvlError, text)
}

function normalizeAttributeErrorText (attr, err) {
  return attr === 'base' ? err : `${localize(attr)} ${err}`
}

// ------------------------------------------------------------
// Localization

// TODO: move this somewhere sensible and/or share w/Rails i18n
const localizedAttrs = {
  created_at: 'created',
  updated_at: 'updated',
  physical_desc: 'physical description',
  loan_date: 'checked out',
  due_date: 'due',
  return_date: 'returned',
  start_date: 'start date',
  end_date: 'end date'
}

function localize (attr) {
  return localizedAttrs[attr] || attr
}
