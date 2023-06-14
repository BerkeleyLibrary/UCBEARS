<script setup lang="ts">
import { computed, ComputedRef, Ref, ref } from "vue";
import { TermEdit } from "../types/Term";
import { useTermsStore } from "../stores/terms";

const { saveTerm } = useTermsStore()

const term: Ref<TermEdit | undefined> = ref(undefined)

function add() {
  term.value = { name: '', default_term: false, start_date: '', end_date: '' }
}

const complete: ComputedRef<boolean> = computed(() => {
  const termVal = term.value
  return !!(termVal && termVal.name && termVal.start_date && termVal.end_date);
})

function save() {
  const termVal = term.value
  if (termVal) {
    saveTerm(termVal).then(clear)
  }
}

function clear() {
  term.value = undefined
}

</script>

<template>
  <tbody id="add-term-widget">
    <tr v-if="term" id="new-term-row" class="add-term">
      <td class="control"><input id="new-term-default_term" v-model.lazy="term.default_term" type="checkbox"></td>
      <td><input id="new-term-name" v-model.lazy="term.name" type="text"></td>
      <td><input id="new-term-start-date" v-model.lazy="term.start_date" type="date"></td>
      <td><input id="new-term-end-date" v-model.lazy="term.end_date" type="date"></td>
      <td colspan="3">
        <div class="actions">
          <button v-if="complete" id="save-term" type="button" class="primary" @click="save">Save</button>
          <button v-else type="button" disabled class="primary disabled" @click="save">Save</button>
          <button id="cancel-add-term" type="button" class="secondary" @click="clear">Cancel</button>
        </div>
      </td>
    </tr>
    <tr>
      <td colspan="6">
        <button v-if="term" type="button" disabled class="primary disabled">Add a term</button>
        <button v-else id="add-term" type="button" class="primary" @click="add">Add a term</button>
      </td>
    </tr>
  </tbody>
</template>
