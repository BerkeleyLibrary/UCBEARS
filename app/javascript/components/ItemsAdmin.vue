<script setup lang="ts">

import FlashAlerts from "./FlashAlerts.vue";
import ItemsTable from "./ItemsTable.vue";
import ItemFilter from "./ItemFilter.vue";
import ItemPaging from "./ItemPaging.vue";
</script>

<template>
  <section id="items-admin" class="admin">
    <flash-alerts/>
    <item-filter/>
    <items-table/>
    <item-paging/>
  </section>
</template>
