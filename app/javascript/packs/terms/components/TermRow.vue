<template>
  <!-- TODO: client-side validation -->
  <tr class="term">
    <td><input :id="`term-${term.id}-name`" v-model.lazy="name" type="text"></td>
    <td><input :id="`term-${term.id}-start-date`" v-model.lazy="startDate" type="date"></td>
    <td><input :id="`term-${term.id}-end-date`" v-model.lazy="endDate" type="date"></td>
    <td class="date">{{ formatDateTime(term.updated_at) }}</td>
    <td class="control">{{ term.item_count }}</td>
    <td class="control">
      <button :id="`term-${term.id}-delete`" class="delete" @click="deleteTerm">
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
    name: {
      get () { return this.term.name },
      set (name) { this.edited({ name: name }) }
    },
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
