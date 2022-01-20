import axios from 'axios'

// TODO: move this out of packs/items
export default {
  getTerms () {
    const termsUrl = new URL('/terms.json', window.location).toString()
    const requestConfig = {
      headers: { Accept: 'application/json' }
    }
    return axios.get(termsUrl, requestConfig).then(response => response.data)
  }
}
