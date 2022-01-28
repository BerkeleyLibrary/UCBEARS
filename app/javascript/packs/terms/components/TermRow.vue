<template>
  <tr class="term">
    <td>{{ term.name }}</td>
    <td>
      <!-- TODO: client-side validation -->
      <input v-model.lazy="startDate" type="date">
    </td>
    <td>
      <!-- TODO: client-side validation -->
      <input v-model.lazy="endDate" type="date">
    </td>
    <td class="control">{{ term.item_count }}</td>
    <td class="control">
      <button class="delete" @click="deleteTerm">
        <img class="action" :alt="`Delete “${term.name}”`" src="/assets/icons/trash-alt.svg">
      </button>
    </td>
  </tr>
</template>

<script>
import i18n from '../../shared/mixins/i18n.js'

export default {
  mixins: [i18n],
  props: {
    term: { type: Object, default: () => {} }
  },
  computed: {
    startDate: {
      get () {
        const startDate = this.term.start_date
        return this.dateToDateInput(startDate)
      },
      set (dateVal) {
        const date = this.dateToISO8601(dateVal)
        this.edited({ start_date: date })
      }
    },
    endDate: {
      get () {
        const endDate = this.term.end_date
        return this.dateToDateInput(endDate)
      },
      set (dateVal) {
        const date = this.dateToISO8601(dateVal)
        this.edited({ end_date: date })
      }
    }
  },
  methods: {
    edited (edit) {
      console.log(`TermRow.edited(${JSON.stringify(edit)})`)
      this.$emit('edited', edit)
    },
    deleteTerm () { this.$emit('removed') }
  }
}
</script>
