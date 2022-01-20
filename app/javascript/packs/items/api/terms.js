import axios from 'axios'

// TODO: move this out of packs/items
export default {
  getAll () {
    const termsUrl = defaultTermsUrl()
    const requestConfig = {
      headers: { Accept: 'application/json' }
    }
    return axios.get(termsUrl, requestConfig).then(response => response.data)
  }
}

function defaultTermsUrl () {
  return new URL('/terms.json', window.location).toString()
}
