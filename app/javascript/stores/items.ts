import { defineStore } from "pinia";
import { ref, Ref } from "vue";
import { Item } from "../types/Item";
import { ItemFilter } from "../types/ItemFilter"
import { ItemsByDirectory, PagedItems } from "../types/PagedItems"
import { Paging } from "../types/Paging";
import { useItemsApi } from "./items-api";

export const useItemsStore = defineStore('items', () => {

  // --------------------------------------------------
  // Exported fields and functions

  const items: Ref<ItemsByDirectory> = ref({})
  const paging: Ref<Paging> = ref(defaultPaging)
  const itemFilter: Ref<ItemFilter> = ref({})

  function saveItem(item: Item) {
    const itemsApi = useItemsApi()
    return itemsApi.update(item).then(setItem)
  }

  function deleteItem(item: Item) {
    const itemsApi = useItemsApi()
    return itemsApi.delete(item).then(removeItem)
  }

  function navigateTo(pageUrl: URL | undefined) {
    // TODO: Clean up ItemPaging.vue so the TypeScript compiler can be sure the URL is not undefined
    if (pageUrl) {
      const itemsApi = useItemsApi()
      return itemsApi.getPage(pageUrl).then(setItems)
    }
  }

  // TODO: just listen for changes to the filter
  function applyFilter() {
    const itemsApi = useItemsApi()
    return itemsApi.findItems(itemFilter.value).then(setItems)
  }

  return { items, paging, itemFilter, saveItem, deleteItem, navigateTo, applyFilter }

  // --------------------------------------------------
  // Internal implementation

  function setItems(pagedItems: PagedItems) {
    paging.value = pagedItems.paging
    items.value = pagedItems.items
  }

  function setItem(item: Item) {
    const itemsByDirectory = items.value
    itemsByDirectory[item.directory] = item
    items.value = itemsByDirectory
  }

  function removeItem(item: Item) {
    const itemsByDirectory = items.value
    delete itemsByDirectory[item.directory]
    items.value = itemsByDirectory
  }
})

const defaultPaging: Paging = {
  currentPage: 1,
  totalPages: 1,
  itemsPerPage: 0,
  currentPageItems: 0,
  totalItems: 0,
  fromItem: 0,
  toItem: 0
}
