<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useTermsStore } from "../stores/terms";
import { useItemsStore } from "../stores/items";

const { terms } = storeToRefs(useTermsStore())
const itemsStore = useItemsStore();
const { itemFilter } = storeToRefs(itemsStore)
const { applyFilter } = itemsStore
</script>

<template>
  <div style="display: contents">
    <form class="search" @submit.prevent>
      <label for="itemFilter-keywords">Keyword search:</label>
      <div class="item-search-field">
        <input
          id="itemFilter-keywords"
          v-model="itemFilter.keywords"
          type="search"
          placeholder="Search by title, author, publisher, or physical description"
          @keydown.enter.prevent
          @keyup.enter="applyFilter()"
          @search="applyFilter()"
        >
        <button type="button" class="primary" @click="$event.target.blur(); applyFilter()">Go</button>
      </div>
    </form>

    <form class="facets">
      <fieldset>
        <legend>Term</legend>

        <template v-for="term in terms" :key="`${term.id}-checkbox`">
          <input :id="`term-${term.id}`" v-model="itemFilter.terms" type="checkbox" :value="term.name" @change="applyFilter()">
          <label :for="`term-${term.id}`">{{ term.name }}</label>
        </template>
      </fieldset>

      <fieldset>
        <legend>Status</legend>

        <input id="itemFilter-active" v-model="itemFilter.active" type="checkbox" true-value="true" :false-value="null" @change="applyFilter()">
        <label for="itemFilter-active">Active only</label>

        <input id="itemFilter-inactive" v-model="itemFilter.active" type="checkbox" true-value="false" :false-value="null" @change="applyFilter()">
        <label for="itemFilter-active">Inactive only</label>
      </fieldset>

      <fieldset>
        <legend>Complete?</legend>

        <input id="itemFilter-complete" v-model="itemFilter.complete" type="checkbox" true-value="true" :false-value="null" @change="applyFilter()">
        <label for="itemFilter-complete">Complete only</label>

        <input id="itemFilter-incomplete" v-model="itemFilter.complete" type="checkbox" true-value="false" :false-value="null" @change="applyFilter()">
        <label for="itemFilter-complete">Incomplete only</label>
      </fieldset>
    </form>
  </div>
</template>
