<template>
  <div style="display: contents">
    <form class="item-search" @submit.prevent>
      <label for="itemQuery-keywords">Keyword search:</label>
      <div class="item-search-field">
        <input
          id="itemQuery-keywords"
          v-model="queryParams.keywords"
          type="search"
          placeholder="Search by title, author, publisher, or physical description"
          @keydown.enter.prevent
          @keyup.enter="apply()"
          @search="apply()"
        >
        <button type="button" class="primary" @click="$event.target.blur(); apply()">Go</button>
      </div>
    </form>

    <form class="item-facets">
      <fieldset>
        <legend>Term</legend>

        <template v-for="term in terms">
          <input :id="`term-${term.id}`" :key="`${term.id}-checkbox`" v-model="queryParams.terms" type="checkbox" :value="term.name" @change="apply()">
          <label :key="`${term.id}-label`" :for="`term-${term.id}`">{{ term.name }}</label>
        </template>
      </fieldset>

      <fieldset>
        <legend>Status</legend>

        <input id="itemQuery-active" v-model="queryParams.active" type="checkbox" true-value="true" :false-value="null" @change="apply()">
        <label for="itemQuery-active">Active only</label>

        <input id="itemQuery-inactive" v-model="queryParams.active" type="checkbox" true-value="false" :false-value="null" @change="apply()">
        <label for="itemQuery-active">Inactive only</label>
      </fieldset>

      <fieldset>
        <legend>Complete?</legend>

        <input id="itemQuery-complete" v-model="queryParams.complete" type="checkbox" true-value="true" :false-value="null" @change="apply()">
        <label for="itemQuery-complete">Complete only</label>

        <input id="itemQuery-incomplete" v-model="queryParams.complete" type="checkbox" true-value="false" :false-value="null" @change="apply()">
        <label for="itemQuery-complete">Incomplete only</label>
      </fieldset>
    </form>
  </div>
</template>

<script>
export default {
  props: {
    params: { type: Object, default: () => {} },
    terms: { type: Array, default: () => [] }
  },
  data: function () {
    // TODO: find a more elegant way to make a local copy
    return { queryParams: Object.assign({}, this.params) }
  },
  methods: {
    apply () {
      this.$emit('applied', this.queryParams)
    }
  }
}
</script>
