<template>
  <tbody>
    <tr v-if="term" class="new-term">
      <td><input v-model.lazy="term.name" type="text"></td>
      <td><input v-model.lazy="term.start_date" type="date"></td>
      <td><input v-model.lazy="term.end_date" type="date"></td>
      <td colspan="3">
        <div class="actions">
          <button v-if="complete" type="button" class="primary" @click="save">Save</button>
          <button v-else type="button" disabled class="primary disabled" @click="save">Save</button>
          <button type="button" class="secondary" @click="clear">Cancel</button>
        </div>
      </td>
    </tr>
    <tr>
      <td colspan="6">
        <button v-if="term" type="button" class="primary disabled">Add a term</button>
        <button v-else type="button" class="primary" @click="add">Add a term</button>
      </td>
    </tr>
  </tbody>
</template>

<script>
import store from '../store'
import termsApi from '../api/terms'
import { mapMutations } from 'vuex'
import { msgSuccess } from '../../shared/store/mixins/flash'

export default {
  store,
  data: function () {
    return { term: {} }
  },
  computed: {
    complete () {
      const term = this.term
      return term.name && term.start_date && term.end_date
    }
  },
  methods: {
    add () { this.term = {} },
    clear () { this.term = {} },
    save () {
      termsApi.create(this.term).then(this.created).catch(this.handleError)
    },
    created (term) {
      this.clear()
      this.setTerm(term)
      this.setMessage(msgSuccess('Term added.'))
    },
    ...mapMutations(['setTerm', 'setMessage', 'handleError'])
  }
}
</script>
