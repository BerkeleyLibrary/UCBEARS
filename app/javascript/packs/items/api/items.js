// ------------------------------------------------------------
// Imports

import axios from 'axios'
import Link from 'http-link-header'

// ------------------------------------------------------------
// Exports

export default {
  get (itemUrl) {
    return axios.get(itemUrl).then(response => response.data)
  },

  getItems: function (itemApiUrl, requestConfig = newRequestConfig()) {
    return axios.get(itemApiUrl, requestConfig).then(response => {
      return {
        items: itemsFromResponse(response),
        paging: pagingFromResponse(response)
      }
    })
  },

  findItems (queryParams) {
    const itemApiUrl = new URL('/items.json', window.location).toString()
    const requestConfig = newRequestConfig(queryParams)
    return this.getItems(itemApiUrl, requestConfig)
  },

  update (item) {
    console.log(`Saving item ${item.directory} (${item.id})`)
    const terms = item.terms || []
    return axios.patch(item.url, {
      item: {
        title: item.title,
        author: item.author,
        copies: item.copies,
        active: item.active,
        publisher: item.publisher,
        physical_desc: item.physical_desc,
        term_ids: terms.map(t => t.id)
      }
    })
      .then(response => response.data)
  },

  delete (item) {
    console.log(`Deleting item ${item.directory} (${item.id})`)
    return axios.delete(item.url).then(response => response.data)
  },

  byDirectory (items) {
    // TODO: should this be a Map?
    return Object.fromEntries(items.map(it => [it.directory, it]))
  }
}

// ------------------------------------------------------------
// Unexported functions

function newRequestConfig (queryParams) {
  return { headers: { Accept: 'application/json' }, params: queryParams }
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
