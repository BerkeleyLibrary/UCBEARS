<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useTermsStore } from "../stores/terms";
import FlashAlerts from "./FlashAlerts.vue";
import TermFilter from "./TermFilter.vue";
import TermRow from "./TermRow.vue";
import { onMounted } from "vue"
import AddTermWidget from "./AddTermWidget.vue"

const { terms } = storeToRefs(useTermsStore())

onMounted(() => {
  console.log('TermsAdmin mounted')
  const { reloadTerms } = useTermsStore()
  reloadTerms()
})

</script>

<template>
  <section id="terms-admin" class="admin">
    <FlashAlerts/>
    <TermFilter/>
    <table>
      <thead>
        <tr>
          <th>Default?</th>
          <th>Name</th>
          <th>Start date</th>
          <th>End date</th>
          <th>Updated</th>
          <th>Items</th>
          <th>Delete</th>
        </tr>
      </thead>
      <tbody>
        <TermRow v-for="term in terms" :key="`term-${term.id}`" :term="term"/>
      </tbody>
      <AddTermWidget/>
    </table>
  </section>
</template>
