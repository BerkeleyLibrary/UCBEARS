<template>
  <tr class="term">
    <td>{{ term.name }}</td>
    <td>{{ term.start_date }}</td>
    <td>{{ term.end_date }}</td>
    <td class="control">{{ term.item_count }}</td>
    <td class="control">
      <button class="delete" @click="deleteTerm">
        <img class="action" :alt="`Delete “${term.name}”`" src="/assets/icons/trash-alt.svg">
      </button>
    </td>
  </tr>
</template>

<script>
export default {
  props: {
    term: { type: Object, default: () => {} }
  },
  methods: {
    edited (edit) { this.$emit('edited', edit) },
    deleteTerm () { this.$emit('removed') }
  }
}
</script>
