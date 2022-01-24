import axios from 'axios'

export default {
  getAll () {
    const termsUrl = defaultTermsUrl()
    const requestConfig = {
      headers: { Accept: 'application/json' }
    }
    return axios.get(termsUrl, requestConfig).then(response => response.data)
  },
  update (term) {
    return axios.patch(term.url, { term: term }).then(response => response.data)
  },
  delete (term) {
    return axios.delete(term.url).then(() => term)
  }
}

function defaultTermsUrl () {
  return new URL('/terms.json', window.location).toString()
}
