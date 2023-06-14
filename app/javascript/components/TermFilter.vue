<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useTermsStore } from "../stores/terms";

const termsStore = useTermsStore()
const { applyFilter } = termsStore
const { termFilter } = storeToRefs(termsStore)
</script>

<template>
  <form class="facets">
    <fieldset>
      <legend>Terms</legend>
      <input id="termFilter-future" v-model="termFilter.future" :true-value="true" :false-value="undefined" type="checkbox" @change="applyFilter">
      <label for="termFilter-future">Future</label>
      <input id="termFilter-current" v-model="termFilter.current" :true-value="true" :false-value="undefined" type="checkbox" @change="applyFilter">
      <label for="termFilter-current">Current</label>
      <input id="termFilter-past" v-model="termFilter.past" :true-value="true" :false-value="undefined" type="checkbox" @change="applyFilter">
      <label for="termFilter-past">Past</label>
    </fieldset>
  </form>
</template>
