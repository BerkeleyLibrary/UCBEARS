import { defineStore } from "pinia";
import { Item } from "../types/Item";
import { ref, Ref } from "vue";
import { useItemsApi } from "./items-api";
import { ItemsByDirectory } from "../types/PagedItems";
import { Paging } from "../types/Paging";

export const useItemsStore = defineStore('items', () => {

  // --------------------------------------------------
  // Exported fields and functions

  const items: Ref<ItemsByDirectory> = ref({})
  const paging: Ref<Paging | undefined> = ref(undefined)
  const itemFilter: Ref<ItemFilter> = ref({})

  function saveItem(item: Item) {
    const itemsApi = useItemsApi()
    return itemsApi.update(item).then(setItem)
  }

  function deleteItem(item: Item) {
    const itemsApi = useItemsApi()
    return itemsApi.delete(item).then(removeItem)
  }

  function navigateTo(pageUrl: URL) {
    const itemsApi = useItemsApi()
    return itemsApi.getPage(pageUrl).then(setItems)
  }

  // TODO: just listen for changes to the filter
  function applyFilter() {
    const itemsApi = useItemsApi()
    return itemsApi.findItems(itemFilter.value).then(setItems)
  }

  return { items, paging, itemFilter, saveItem, deleteItem, navigateTo, applyFilter}

  // --------------------------------------------------
  // Internal implementation

  function setItems(pagedItems) {
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
