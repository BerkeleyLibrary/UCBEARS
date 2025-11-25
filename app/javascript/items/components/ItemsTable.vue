<template>
  <table v-if="items" id="items-table" tabindex="-1">
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
      <item-row
        v-for="item in items"
        :key="item.directory"
        :item="item"
        :all-terms="terms"
        @edited="edit(item)($event)"
        @removed="remove(item)"
      />
    </tbody>
  </table>
</template>

<script>
import ItemRow from './ItemRow'

export default {
  components: { ItemRow },
  props: {
    table: { type: Object, default: () => {} },
    terms: { type: Array, default: () => [] }
  },
  computed: {
    items () { return this.table.items },
    paging () { return this.table.paging }
  },
  methods: {
    edit (item) {
      return (change) => this.$emit('edited', { item, change })
    },
    remove (item) { this.$emit('removed', item) }
  }
}
</script>
