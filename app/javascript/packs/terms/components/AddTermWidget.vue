<template>
  <tbody>
    <tr v-if="term" class="new-term">
      <td><input v-model.lazy="term.name" type="text"></td>
      <td><input v-model.lazy="term.start_date" type="date"></td>
      <td><input v-model.lazy="term.end_date" type="date"></td>
      <td colspan="3">
        <div class="actions">
          <button type="button" class="primary" @click="save">Save</button>
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
import { mapMutations } from 'vuex'
import termsApi from '../api/terms'

export default {
  store,
  data: function () {
    return { term: null }
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
    },
    handleError (error) {
      console.log(error)
      this.setErrors(error?.response?.data)
    },
    ...mapMutations(['setTerm', 'setErrors'])
  }
}
</script>
