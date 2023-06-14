import axios, { AxiosRequestConfig, AxiosResponse } from 'axios'
import Link from 'http-link-header'
import { defineStore } from "pinia";
import { ref, Ref } from 'vue'
import { Item } from "../types/Item";
import { ItemsByDirectory, PagedItems } from "../types/PagedItems";
import { Paging } from "../types/Paging";
import { useFlashStore } from "./flash";

// TODO: Roll this into Items store
export const useItemsApi = defineStore('items-api', () => {
  const itemsUrl: Ref<string> = ref(new URL('/items.json', window.location.href).toString())

  function get(itemUrl): Promise<Item> {
    return axios.get(itemUrl).then(response => response.data)
  }

  function getAll() {
    return getItems()
  }

  function getPage(pageUrl: URL): Promise<PagedItems> {
    return getItems(pageUrl.toString())
  }

  function findItems(filter: ItemFilter): Promise<PagedItems> {
    return getItems(itemsUrl.value, filter)
  }

  function update(item: Item): Promise<Item> {
    return axios.patch(item.url, { item }).then(response => {
      const { clearMessages } = useFlashStore()
      clearMessages()
      console.log('Item saved.')
      return response.data
    })
  }

  function _delete(item: Item): Promise<Item> {
    return axios.delete(item.url).then(() => {
      const { setMessage } = useFlashStore()
      setMessage('Item deleted.')
      return item;
    })
  }

  return { get, getAll, getPage, findItems, update, delete: _delete}

  function getItems(url: string = itemsUrl.value, filter: ItemFilter = {}): Promise<PagedItems> {
    const requestConfig: AxiosRequestConfig = { headers: { Accept: 'application/json' } } // TODO: global Axios config?
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
})

function pagingFromResponse (response: AxiosResponse): Paging {
  const headers = response.headers

  const currentPage = getInt(headers, 'current-page', 1);
  const totalPages = getInt(headers, 'total-pages', 1);
  const itemsPerPage = getInt(headers, 'page-items', 0);
  const currentPageItems = getInt(headers, 'current-page-items', 0);
  const totalItems = getInt(headers, 'total-count', 0);
  const fromItem = ((currentPage - 1) * itemsPerPage) + 1
  const toItem = (fromItem + currentPageItems) - 1

  const paging: Paging = {
    currentPage,
    totalPages,
    itemsPerPage,
    currentPageItems,
    totalItems,
    fromItem,
    toItem
  }

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

function itemsFromResponse (response: AxiosResponse<Item[]>): ItemsByDirectory {
  const data = response.data
  if (!data || typeof data.map !== 'function') {
    return {}
  }
  return Object.fromEntries(data.map(it => [it.directory, it]))
}

function getInt (headers, name, defaultValue) {
  return parseInt(headers[name]) || defaultValue
}
