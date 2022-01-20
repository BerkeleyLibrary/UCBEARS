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
    <td class="date">{{ item.updated_at }}</td>
    <td v-if="item.complete" key="complete?" class="control">Yes</td>
    <td v-else key="complete?" :title="item.reason_incomplete" class="control">No</td>
    <td class="control">
      <input v-model.number.lazy="item.copies" type="number" @change="updateItem()">
    </td>
    <td>
      <ul>
        <li v-for="term in terms" :key="`term-${term.id}`">
          <input :id="`term-${term.id}`" v-model.lazy="item.terms" type="checkbox" :value="term" @change="updateItem()">
          <label :for="`term-${term.id}`">{{ term.name }}</label>
        </li>
      </ul>
    </td>
    <td class="control">
      <input v-model.lazy="item.active" type="checkbox" :disabled="item.complete" :title="item.reason_incomplete" @change="updateItem()">
    </td>
    <td class="control">
      <button class="delete" :disabled="item.complete" :title="item.complete ? 'Only incomplete items can be deleted.' : `Delete “${item.title}”`" @click="deleteItem()">
        <img class="action" src="/assets/icons/trash-alt.svg">
      </button>
    </td>
  </tr>
</template>

<script>
import itemsApi from '../api/items'

export default {
  props: {
    rowItem: { type: Object, default: () => {} },
    terms: { type: Array, default: () => [] }
  },
  data: function () {
    return { item: this.rowItem }
  },
  methods: {
    updateItem () {
      itemsApi.update(this.item).then(updatedItem => this.$emit('updated', updatedItem))
    },
    deleteItem () {
      itemsApi.delete(this.item).then(() => this.$emit('removed', this.item))
    }
  }
}
</script>
