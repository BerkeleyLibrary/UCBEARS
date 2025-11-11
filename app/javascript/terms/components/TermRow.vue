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
    <td>
      <input
        :id="`term-${term.id}-name`"
        v-model.lazy="name"
        type="text"
        aria-label="Term name"
        @blur="checkName($event)"
      >
      <span
        :id="`name-error-${term.id}`"
        class="visually-hidden"
        aria-live="assertive"
      ></span>
    </td>
    <td>
      <input
        :id="`term-${term.id}-start-date`"
        v-model.lazy="startDate"
        type="date"
        @keyup.enter="commitStartDate"
        @blur="commitStartDate($event)"
        aria-label="Start date"
      >
      <span
        :id="`start-error-${term.id}`"
        class="visually-hidden"
        aria-live="assertive"
      ></span>
    </td>
    <td>
      <input
        :id="`term-${term.id}-end-date`"
        v-model.lazy="endDate"
        type="date"
        @keyup.enter="commitEndDate"
        @blur="commitEndDate($event)"
        aria-label="End date"
      >
      <span
        :id="`end-error-${term.id}`"
        class="visually-hidden"
        aria-live="assertive"
      ></span>
    </td>
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
    term: { type: Object, default: () => ({}) }
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
    async commitStartDate (event) {
      await this.$nextTick()
      const inputEl = event?.target
      const startDateVal = inputEl?.value?.trim()
      const errorEl = document.getElementById(`start-error-${this.term.id}`)

      // Clear previous message
      if (errorEl) errorEl.textContent = ''

      if (!startDateVal) {
        // Show error message (for screen readers + sighted users if desired)
        if (errorEl) errorEl.textContent = 'Start date must have a valid start date.'

        // Delay focus slightly so screen reader announces error first
        setTimeout(() => {
          inputEl?.focus()
        }, 400)
      }
      if (this.shadowStartDate !== this.term.start_date) {
        this.edited({ start_date: this.shadowStartDate })
      }
    },
    async commitEndDate (event) {
      await this.$nextTick()

      const inputEl = event?.target
      const endDateVal = inputEl?.value?.trim()
      const errorEl = document.getElementById(`end-error-${this.term.id}`)
      const startDateVal = this.shadowStartDate

      // Clear previous message
      if (errorEl) errorEl.textContent = ''

      // Announce an error, then refocus input back to endDate
      const announceError = (message) => {
        if (!errorEl) return false
        errorEl.textContent = message
        errorEl.setAttribute('tabindex', '-1')
        errorEl.focus()

        // Wait long enough for SR to finish reading before moving focus back
        setTimeout(() => {
          inputEl?.focus()
          errorEl.removeAttribute('tabindex')
        }, 2000) // slightly longer than before

        return true
      }

      let hasError = false

      // Validation 1: must not be blank
      if (!endDateVal) {
        hasError = announceError('End date must have an end date.')
      }

      // Validation 2: must be after start date
      else if (startDateVal && new Date(endDateVal) < new Date(startDateVal)) {
        hasError = announceError('End date cannot be before start date.')
      }

      // Always commit the shadow value so the flash can trigger,
      // but only if the value actually changed.
      if (this.shadowEndDate !== this.term.end_date) {
        this.edited({ end_date: this.shadowEndDate })
      }

      // Prevent accidental multiple announcements
      if (hasError) return
    },
    edited (edit) {
      console.log(`TermRow.edited(${JSON.stringify(edit)})`)
      this.$emit('edited', edit)
    },
    deleteTerm () { this.$emit('removed') },
    
    async checkName (event) {
      await this.$nextTick()
      
      const nameValue = event.target.value.trim()
      const errorEl = document.getElementById(`name-error-${this.term.id}`)
      const inputEl = event.target
      
      if (!nameValue) {
        // Move focus back first, before announcing the error
        inputEl.focus()

        // Small delay so screen reader finishes focus announcement
        setTimeout(() => {
          if (errorEl) errorEl.textContent = 'Error: Name is required.'
        }, 200)
      } else {
        if (errorEl) errorEl.textContent = ''
      }
    }
  }
}
</script>
