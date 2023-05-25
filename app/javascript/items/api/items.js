// ------------------------------------------------------------
// Imports

import axios from 'axios'
import Link from 'http-link-header'

// ------------------------------------------------------------
// Exports

function defaultItemsUrl () {
  return new URL('/items.json', window.location).toString()
}

export default {
  get (itemUrl) {
    return axios.get(itemUrl).then(response => response.data)
  },

  getAll () {
    return getItems()
  },

  getPage (itemApiUrl) {
    return getItems({ url: itemApiUrl })
  },

  findItems (itemFilter) {
    return getItems({ filter: itemFilter })
  },

  update (item) {
    return axios.patch(item.url, { item: item }).then(response => response.data)
  },

  delete (item) {
    return axios.delete(item.url).then(() => item)
  }
}

// ------------------------------------------------------------
// Unexported functions

function getItems ({ url = defaultItemsUrl(), filter } = {}) {
  const requestConfig = { headers: { Accept: 'application/json' } } // TODO: global Axios config?
  if (filter) {
    requestConfig.params = filter
  }
  return axios.get(url, requestConfig).then(response => {
    return {
      items: itemsFromResponse(response),
      paging: pagingFromResponse(response)
    }
  })
}

function pagingFromResponse (response) {
  const headers = response.headers
  const paging = {
    currentPage: getInt(headers, 'current-page', 1),
    totalPages: getInt(headers, 'total-pages', 1),
    itemsPerPage: getInt(headers, 'page-items', 0),
    currentPageItems: getInt(headers, 'current-page-items', 0),
    totalItems: getInt(headers, 'total-count', 0)
  }
  paging.fromItem = ((paging.currentPage - 1) * paging.itemsPerPage) + 1
  paging.toItem = (paging.fromItem + paging.currentPageItems) - 1

  const linkHeader = headers.link
  if (!linkHeader) {
    return paging
  }

  const links = Link.parse(linkHeader)
  for (const rel of ['first', 'prev', 'next', 'last']) {
    if (links.has('rel', rel)) {
      const urlStr = links.get('rel', rel)[0].uri
      paging[rel] = new URL(urlStr)
    }
  }

  return paging
}

function itemsFromResponse (response) {
  const data = response.data
  if (data && typeof data.map !== 'function') {
    return {}
  }
  return Object.fromEntries(data.map(it => [it.directory, it]))
}

function getInt (headers, name, defaultValue) {
  return parseInt(headers[name]) || defaultValue
}
