<script setup lang="ts">
import { onMounted } from "vue"
import FlashAlerts from "./FlashAlerts.vue";
import ItemsTable from "./ItemsTable.vue";
import ItemFilter from "./ItemFilter.vue";
import ItemPaging from "./ItemPaging.vue";
import { useTermsStore } from "../stores/terms"
import { useItemsStore } from "../stores/items"

onMounted(() => {
  console.log('ItemsAdmin mounted')
  const { reloadTerms } = useTermsStore()
  const { reloadItems } = useItemsStore()

  reloadTerms().then(reloadItems)
})

</script>

<template>
  <section id="items-admin" class="admin">
    <flash-alerts/>
    <item-filter/>
    <items-table/>
    <item-paging/>
  </section>
</template>
