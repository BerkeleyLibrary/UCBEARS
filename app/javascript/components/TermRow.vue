<script setup lang="ts">
import { computed, Ref, ref, WritableComputedRef } from "vue";
import { Term } from "../types/Term";
import { useTermsStore } from "../stores/terms";
import i18n from '../helpers/i18n'

const { saveTerm, deleteTerm } = useTermsStore()
const { dateToDateInput, dateToISO8601, formatDateTime } = i18n

const props = defineProps<{ term: Term }>()
const termPatch: Ref<Term> = ref({ ...props.term })

const startDate = dateInputModel('start_date')
const endDate = dateInputModel('end_date')

function commitStartDate() {
  const patch = termPatch.value;
  if (patch.start_date !== props.term.start_date) {
    saveTerm(patch)
  }
}

function commitEndDate() {
  const patch = termPatch.value;
  if (patch.end_date !== props.term.end_date) {
    saveTerm(patch)
  }
}

function dateInputModel(dateAttr: 'start_date' | 'end_date'): WritableComputedRef<string> {
  return computed({
    get() {
      const patch = termPatch.value;
      const date = patch[dateAttr]
      return dateToDateInput(date)
    },
    set(v: string) {
      const patch = termPatch.value;
      patch[dateAttr] = dateToISO8601(v)
      termPatch.value = patch
    }
  })
}

function confirmDelete(): boolean {
  const patch = termPatch.value;
  const itemCount = patch.item_count;
  if (itemCount === 0) {
    return true
  }
  const itemsStr = itemCount > 1 ? 'items' : 'item'
  const msg = `Term ${patch.name} has ${itemCount} ${itemsStr}. Really delete it?`
  return window.confirm(msg)
}

function doDelete() {
  if (confirmDelete()) {
    deleteTerm(termPatch.value)
  }
}

</script>

<template>
  <!-- TODO: client-side validation -->
  <tr :id="`term-${term.id}`" class="term">
    <td class="control">
      <input :id="`term-${term.id}-default_term`" v-model.lazy="termPatch.default_term" type="checkbox">
    </td>
    <td><input :id="`term-${term.id}-name`" v-model.lazy="termPatch.name" type="text"></td>
    <td><input :id="`term-${term.id}-start-date`" v-model.lazy="startDate" type="date" @keyup.enter="commitStartDate" @blur="commitStartDate"></td>
    <td><input :id="`term-${term.id}-end-date`" v-model.lazy="endDate" type="date" @keyup.enter="commitEndDate" @blur="commitEndDate"></td>
    <td class="date">{{ formatDateTime(term.updated_at) }}</td>
    <td class="control">{{ term.item_count }}</td>
    <td class="control">
      <button :id="`term-${term.id}-delete`" :disabled="term.default_term" class="delete" :title="term.default_term ? 'The current default term cannot be deleted.' : `Delete term “${term.name}”`" @click="doDelete">
        <img class="action" :alt="`Delete “${term.name}”`" src="/assets/icons/trash-alt.svg">
      </button>
    </td>
  </tr>
</template>
