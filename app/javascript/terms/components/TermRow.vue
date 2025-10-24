<template>
  <!-- TODO: client-side validation -->
  <tr :id="`term-${term.id}`" class="term">
    <td class="control">
      <input
        :id="`term-${term.id}-default_term`"
        v-model.lazy="default_term"
        type="checkbox"
        :aria-label="`Set ${term.name} as default term`"
      >
    </td>
    <td><input :id="`term-${term.id}-name`" v-model.lazy="name" type="text"></td>
    <td><input :id="`term-${term.id}-start-date`" v-model.lazy="startDate" type="date" @keyup.enter="commitStartDate" @blur="commitStartDate"></td>
    <td><input :id="`term-${term.id}-end-date`" v-model.lazy="endDate" type="date" @keyup.enter="commitEndDate" @blur="commitEndDate"></td>
    <td class="date">{{ formatDateTime(term.updated_at) }}</td>
    <td class="control">{{ term.item_count }}</td>
    <td class="control">
      <button :id="`term-${term.id}-delete`" :disabled="term.default_term" class="delete" :title="term.default_term ? 'The current default term cannot be deleted.' : `Delete term “${term.name}”`" @click="deleteTerm">
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
  data: function () {
    return ({
      shadowStartDate: this.term.start_date,
      shadowEndDate: this.term.end_date
    })
  },
  computed: {
    default_term: {
      get () { return this.term.default_term },
      set (v) { this.edited({ default_term: v }) }
    },
    name: {
      get () { return this.term.name },
      set (name) { this.edited({ name }) }
    },
    startDate: {
      get () {
        const startDate = this.term.start_date
        return this.dateToDateInput(startDate)
      },
      set (dateVal) {
        this.shadowStartDate = this.dateToISO8601(dateVal)
      }
    },
    endDate: {
      get () {
        const endDate = this.term.end_date
        return this.dateToDateInput(endDate)
      },
      set (dateVal) {
        this.shadowEndDate = this.dateToISO8601(dateVal)
      }
    }
  },
  methods: {
    commitStartDate () {
      if (this.shadowStartDate !== this.term.start_date) {
        this.edited({ start_date: this.shadowStartDate })
      }
    },
    commitEndDate () {
      if (this.shadowEndDate !== this.term.end_date) {
        this.edited({ end_date: this.shadowEndDate })
      }
    },
    edited (edit) {
      console.log(`TermRow.edited(${JSON.stringify(edit)})`)
      this.$emit('edited', edit)
    },
    deleteTerm () { this.$emit('removed') }
  }
}
</script>
