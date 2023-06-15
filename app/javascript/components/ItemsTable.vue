<script setup lang="ts">
import ItemRow from './ItemRow.vue'
import { storeToRefs } from "pinia";
import { useItemsStore } from "../stores/items";

const { items, paging } = storeToRefs(useItemsStore())

</script>

<template>
  <table v-if="items">
    <caption v-if="paging">Viewing results {{ paging.fromItem }} to {{ paging.toItem }} of {{ paging.totalItems }}</caption>
    <thead>
      <tr>
        <th>Edit</th>
        <th>Item</th>
        <th>View</th>
        <th>Link</th>
        <th>Updated</th>
        <th>Complete</th>
        <th>Copies</th>
        <th>Term</th>
        <th>Active</th>
        <th>Delete</th>
      </tr>
    </thead>
    <tbody>
      <ItemRow
        v-for="item in items"
        :key="item.directory"
        :item="item"
      />
    </tbody>
  </table>
</template>
