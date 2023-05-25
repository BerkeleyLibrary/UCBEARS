<template>
  <form class="facets">
    <fieldset>
      <legend>Terms</legend>
      <input id="termFilter-future" v-model="termFilter.future" :true-value="true" :false-value="null" type="checkbox" @change="apply()">
      <label for="termFilter-future">Future</label>
      <input id="termFilter-current" v-model="termFilter.current" :true-value="true" :false-value="null" type="checkbox" @change="apply()">
      <label for="termFilter-current">Current</label>
      <input id="termFilter-past" v-model="termFilter.past" :true-value="true" :false-value="null" type="checkbox" @change="apply()">
      <label for="termFilter-past">Past</label>
    </fieldset>
  </form>
</template>

<script>
export default {
  props: {
    filter: {
      type: Object,
      default: () => ({ future: null, past: null, current: null })
    }
  },
  data: function () {
    return { termFilter: { ...this.filter } }
  },
  methods: {
    apply () {
      this.$emit('applied', this.termFilter)
    }
  }
}
</script>
