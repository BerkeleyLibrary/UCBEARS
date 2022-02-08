<template>
  <tbody id="add-term-widget">
    <tr v-if="term" class="add-term">
      <td><input id="new-term-name" v-model.lazy="term.name" type="text"></td>
      <td><input id="new-term-start-date" v-model.lazy="term.start_date" type="date"></td>
      <td><input id="new-term-end-date" v-model.lazy="term.end_date" type="date"></td>
      <td colspan="3">
        <div class="actions">
          <button v-if="complete" id="save-term" type="button" class="primary" @click="save">Save</button>
          <button v-else type="button" disabled class="primary disabled" @click="save">Save</button>
          <button id="cancel-add-term" type="button" class="secondary" @click="clear">Cancel</button>
        </div>
      </td>
    </tr>
    <tr>
      <td colspan="6">
        <button v-if="term" type="button" disabled class="primary disabled">Add a term</button>
        <button v-else id="add-term" type="button" class="primary" @click="add">Add a term</button>
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
    return { term: null }
  },
  computed: {
    complete () {
      const term = this.term
      return term.name && term.start_date && term.end_date
    }
  },
  methods: {
    add () { this.term = {} },
    clear () { this.term = null },
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
