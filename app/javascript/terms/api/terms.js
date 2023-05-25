import axios from 'axios'

export default {
  getAll () {
    return getTerms()
  },

  findTerms (termFilter) {
    return getTerms({ filter: termFilter })
  },

  create (term) {
    const url = defaultTermsUrl()
    console.log(`termsApi.create(url, { term: ${JSON.stringify(term)} })`)
    return axios.post(url, { term: term }).then(response => response.data)
  },

  update (term) {
    console.log(`termsApi.update(${term.url}, { term: ${JSON.stringify(term)} })`)
    return axios.patch(term.url, { term: term }).then(response => response.data)
  },

  delete (term) {
    return axios.delete(term.url).then(() => term)
  }
}

function getTerms ({ url = defaultTermsUrl(), filter } = {}) {
  const requestConfig = { headers: { Accept: 'application/json' } } // TODO: global Axios config?
  if (filter) {
    requestConfig.params = filter
  }
  return axios.get(url, requestConfig).then(response => response.data)
}

function defaultTermsUrl () {
  return new URL('/terms.json', window.location).toString()
}
