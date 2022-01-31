<template>
  <tbody>
    <tr v-if="newTerm" class="new-term">
      <td><input v-model.lazy="newTerm.name" type="text"></td>
      <td><input v-model.lazy="newTerm.startDate" type="date"></td>
      <td><input v-model.lazy="newTerm.endDate" type="date"></td>
      <td colspan="3">
        <div class="actions">
          <button type="button" class="primary" @click="saveNewTerm">Save</button>
          <button type="button" class="secondary" @click="cancelNewTerm">Cancel</button>
        </div>
      </td>
    </tr>
    <tr>
      <td colspan="6">
        <button v-if="newTerm" type="button" class="primary disabled">Add a term</button>
        <button v-else type="button" class="primary" @click="addNewTerm">Add a term</button>
      </td>
    </tr>
  </tbody>
</template>

<script>
export default {
  data: function () {
    return { newTerm: null }
  },
  methods: {
    addNewTerm () {
      this.newTerm = {}
    },
    cancelNewTerm () {
      this.newTerm = null
    }
  }
}
</script>
