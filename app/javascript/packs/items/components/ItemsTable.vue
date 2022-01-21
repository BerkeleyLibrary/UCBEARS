<template>
  <table>
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
        :row-item="item"
        :terms="terms"
        @updated="update"
        @removed="remove"
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
    items () {
      return this.table.items || {}
    },
    paging () {
      return this.table.paging || {}
    }
  },
  methods: {
    update (item) {
      this.$emit('updated', item)
    },
    remove (item) {
      this.$emit('removed', item)
    }
  }
}
</script>
