<template>
  <tr class="item">
    <td class="control">
      <a :href="item.edit_url" class="icon-link" target="_blank" :title="`Edit “${item.title}”`"><img src="/assets/icons/edit.svg" :alt="`Edit “${item.title}”`" class="action"></a>
    </td>
    <td>
      <p class="title">
        {{ item.title }}
      </p>
      <p class="author-name">
        {{ item.author }}
      </p>
      <p class="metadata">
        {{ item.publisher }}
        {{ item.physical_desc }}
      </p>
    </td>
    <td class="control">
      <a :href="item.show_url" class="icon-link" target="_blank" :title="`Admin view of “${item.title}”`"><img src="/assets/icons/eye.svg" :alt="`Admin view of “${item.title}”`" class="action"></a>
    </td>
    <td class="control">
      <a :href="item.view_url" class="icon-link" target="_blank" :title="`Permalink to “${item.title}” patron view`"><img src="/assets/icons/link.svg" :alt="`Permalink to “${item.title}” patron view`" class="action"></a>
    </td>
    <td class="date">{{ formatDateTime(item.updated_at) }}</td>
    <td v-if="item.complete" key="complete?" class="control">Yes</td>
    <td v-else key="complete?" :title="item.reason_incomplete" class="control">No</td>
    <td class="control">
      <!-- TODO: client-side validation -->
      <input v-model.number.lazy="copies" type="number">
    </td>
    <td>
      <ul>
        <li v-for="term in allTerms" :key="`term-${term.id}`">
          <input :id="`term-${term.id}`" v-model.lazy="term_ids" type="checkbox" :value="term.id">
          <label :for="`term-${term.id}`">{{ term.name }}</label>
        </li>
      </ul>
    </td>
    <td class="control">
      <input v-model.lazy="active" type="checkbox" :disabled="!item.complete" :title="item.reason_incomplete">
    </td>
    <td class="control">
      <button class="delete" :disabled="item.complete" :title="item.complete ? 'Only incomplete items can be deleted.' : `Delete “${item.title}”`" @click="deleteItem">
        <img class="action" :alt="`Delete “${item.title}”`" src="/assets/icons/trash-alt.svg">
      </button>
    </td>
  </tr>
</template>

<script>
import i18n from '../../shared/mixins/i18n.js'

export default {
  mixins: [i18n],
  props: {
    item: { type: Object, default: () => {} },
    allTerms: { type: Array, default: () => [] }
  },
  computed: {
    term_ids: {
      get () { return this.item.terms.map(t => t.id) },
      set (ids) { this.edited({ term_ids: ids }) }
    },
    copies: {
      get () { return this.item.copies },
      set (copies) { this.edited({ copies: copies }) }
    },
    active: {
      get () { return this.item.active },
      set (active) { this.edited({ active: active }) }
    }
  },
  methods: {
    edited (edit) { this.$emit('edited', edit) },
    deleteItem () { this.$emit('removed') }
  }
}
</script>
