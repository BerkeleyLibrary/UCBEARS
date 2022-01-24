<template>
  <table v-if="terms">
    <thead>
      <tr>
        <th>Name</th>
        <th>Start date</th>
        <th>End date</th>
        <th>Items</th>
        <th>Delete</th>
      </tr>
    </thead>
    <tbody>
      <term-row
        v-for="term in terms"
        :key="term.id"
        :term="term"
        @edited="edit(term)($event)"
        @removed="remove(term)"
      />
    </tbody>
  </table>
</template>

<script>
import TermRow from './TermRow'

export default {
  components: { TermRow },
  props: {
    terms: { type: Array, default: () => [] }
  },
  methods: {
    edit (term) {
      return (change) => this.$emit('edited', { term: term, change: change })
    },
    remove (term) { this.$emit('removed', term) }
  }
}
</script>
