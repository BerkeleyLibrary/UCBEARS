<script setup lang="ts">
import { computed, Ref, ref, WritableComputedRef } from "vue";
import { Item } from "../types/Item";
import { Term, TermId } from "../types/Term";
import { useItemsStore } from "../stores/items";
import { useTermsStore } from "../stores/terms";
import { storeToRefs } from "pinia";
import i18n from '../helpers/i18n'

const { formatDateTime } = i18n

const { terms } = storeToRefs(useTermsStore())
const { saveItem, deleteItem } = useItemsStore()

const props = defineProps<{ item: Item }>()
const itemPatch: Ref<Item> = ref({ ...props.item })

const active: WritableComputedRef<boolean> = computed({
  get() {
    return itemPatch.value.active
  },
  set(v) {
    const patch = itemPatch.value;
    patch.active = v
    saveItem(patch)
  }
})

const termIds: WritableComputedRef<TermId[]> = computed({
  get() {
    return itemPatch.value.terms.map((t) => t.id)
  },
  set(v: TermId[]) {
    const patch = itemPatch.value;
    const allTerms: Term[] = terms.value
    patch.terms = allTerms.filter((t) => v.includes(t.id))
    saveItem(patch)
  }
})

const copies: WritableComputedRef<number> = computed({
  get() {
    return itemPatch.value.copies
  },
  set(v: number) {
    const patch = itemPatch.value
    patch.copies = v
    saveItem(patch)
  }
})

</script>

<template>
  <tr class="item">
    <td class="control">
      <a :href="itemPatch.edit_url" class="icon-link" target="_blank" :title="`Edit “${itemPatch.title}”`"><img src="/assets/icons/edit.svg" :alt="`Edit “${itemPatch.title}”`" class="action"></a>
    </td>
    <td>
      <p class="title">
        {{ itemPatch.title }}
      </p>
      <p class="author-name">
        {{ itemPatch.author }}
      </p>
      <p class="metadata">
        {{ itemPatch.publisher }}
        {{ itemPatch.physical_desc }}
      </p>
    </td>
    <td class="control">
      <a :href="itemPatch.show_url" class="icon-link" target="_blank" :title="`Admin view of “${itemPatch.title}”`"><img src="/assets/icons/eye.svg" :alt="`Admin view of “${itemPatch.title}”`" class="action"></a>
    </td>
    <td class="control">
      <a :href="itemPatch.view_url" class="icon-link" target="_blank" :title="`Permalink to “${itemPatch.title}” patron view`"><img src="/assets/icons/link.svg" :alt="`Permalink to “${itemPatch.title}” patron view`" class="action"></a>
    </td>
    <td class="date">{{ formatDateTime(itemPatch.updated_at) }}</td>
    <td v-if="itemPatch.complete" key="complete-true" class="control">Yes</td>
    <td v-else key="complete-false" :title="itemPatch.reason_incomplete" class="control">No</td>
    <td class="control">
      <!-- TODO: client-side validation -->
      <input v-model.number.lazy="copies" type="number">
    </td>
    <td>
      <ul>
        <li v-for="term in terms" :key="`term-${term.id}`">
          <input :id="`term-${term.id}`" v-model.lazy="termIds" type="checkbox" :value="term.id">
          <label :for="`term-${term.id}`">{{ term.name }}</label>
        </li>
      </ul>
    </td>
    <td class="control">
      <input v-model.lazy="active" type="checkbox" :disabled="!itemPatch.complete" :title="itemPatch.reason_incomplete">
    </td>
    <td class="control">
      <button class="delete" :disabled="itemPatch.complete" :title="itemPatch.complete ? 'Only incomplete items can be deleted.' : `Delete “${itemPatch.title}”`" @click="deleteItem">
        <img class="action" :alt="`Delete “${itemPatch.title}”`" src="/assets/icons/trash-alt.svg">
      </button>
    </td>
  </tr>
</template>
