<template>
  <section class="items-table">
    <aside
      v-if="Array.isArray(errors) && errors.length"
      class="flash"
    >
      <template v-for="(error, index) in errors">
        <input
          :id="`flash-dismiss-items-table-${index}`"
          :key="error"
          type="checkbox"
          class="flash-dismiss"
          @change="errors.splice(index, 1)"
        >
        <div :key="error" class="flash alert">
          <label
            :for="`flash-dismiss-items-table-${index}`"
            class="flash-dismiss-label"
          >
            <img
              src="/assets/icons/times-circle.svg"
              class="flash-dismiss-icon"
              alt="Hide alert"
            >
          </label>
          <p
            class="flash"
            role="alert"
          >
            {{ error }}
          </p>
        </div>
      </template>
    </aside>

    <form class="item-search" @submit.prevent>
      <label for="itemQuery-keywords">Keyword search:</label>
      <div class="item-search-field">
        <!-- TODO: trigger reload on clear -->
        <input
          id="itemQuery-keywords"
          v-model="queryParams.keywords"
          type="search"
          placeholder="Search by title, author, publisher, or physical description"
          @keydown.enter.prevent
          @keyup.enter="submitQuery()"
        >
        <button type="button" class="primary" @click="$event.target.blur(); submitQuery()">Go</button>
      </div>
    </form>

    <form class="item-facets">
      <fieldset>
        <legend>Term</legend>

        <template v-for="term in terms">
          <input :id="`term-${term.id}`" :key="`${term.id}-checkbox`" v-model="queryParams.terms" type="checkbox" :value="term.name" @change="submitQuery()">
          <label :key="`${term.id}-label`" :for="`term-${term.id}`">{{ term.name }}</label>
        </template>
      </fieldset>

      <fieldset>
        <legend>Status</legend>

        <input id="itemQuery-active" v-model="queryParams.active" type="checkbox" true-value="true" :false-value="null" @change="submitQuery()">
        <label for="itemQuery-active">Active only</label>

        <input id="itemQuery-inactive" v-model="queryParams.active" type="checkbox" true-value="false" :false-value="null" @change="submitQuery()">
        <label for="itemQuery-active">Inactive only</label>
      </fieldset>

      <fieldset>
        <legend>Complete?</legend>

        <input id="itemQuery-complete" v-model="queryParams.complete" type="checkbox" true-value="true" :false-value="null" @change="submitQuery()">
        <label for="itemQuery-complete">Complete only</label>

        <input id="itemQuery-incomplete" v-model="queryParams.complete" type="checkbox" true-value="false" :false-value="null" @change="submitQuery()">
        <label for="itemQuery-complete">Incomplete only</label>
      </fieldset>
    </form>

    <table>
      <caption v-if="paging">Viewing results {{ paging.fromItem }} to {{ paging.toItem }} of {{ paging.totalItems }}</caption>
      <thead>
        <tr>
          <th>Edit</th>
          <th>Item</th>
          <th>View</th>
          <th>Link</th>
          <th>Updated</th>
          <th>Complete</th>
          <th>Copies</th>
          <th>Term</th>
          <th>Active</th>
          <th>Delete</th>
        </tr>
      </thead>
      <tbody>
        <item-row
          v-for="item in items"
          :key="item.directory"
          :row-item="item"
          :terms="terms"
          @updated="setItem"
          @removed="removeItem"
        />
      </tbody>
    </table>

    <!-- TODO: extract this to its own component -->
    <nav
      v-if="paging"
      class="pagination"
    >
      <ul>
        <li>
          <a
            v-if="paging.first && paging.currentPage !== 1"
            href="#"
            rel="first"
            title="First page"
            @click="navigateTo(paging.first)"
          >≪</a>
          <template v-else>
            ≪
          </template>
        </li>
        <li>
          <a
            v-if="paging.prev && paging.currentPage > 1"
            href="#"
            rel="prev"
            title="Previous page"
            @click="navigateTo(paging.prev)"
          >&lt;</a>
          <template v-else>
            &lt;
          </template>
        </li>
        <li>
          Page {{ paging.currentPage }} of {{ paging.totalPages }}
        </li>
        <li>
          <a
            v-if="paging.next && paging.currentPage < paging.totalPages"
            href="#"
            rel="next"
            title="Next page"
            @click="navigateTo(paging.next)"
          >&gt;</a>
          <template v-else>
            &gt;
          </template>
        </li>
        <li>
          <a
            v-if="paging.last && paging.currentPage !== paging.totalPages"
            href="#"
            rel="last"
            title="Last page"
            @click="navigateTo(paging.last)"
          >≫</a>
          <template v-else>
            ≫
          </template>
        </li>
      </ul>
    </nav>
  </section>
</template>

<script>
import Vue from 'vue'
import itemsApi from '../api/items'
import termsApi from '../api/terms'
import ItemRow from './ItemRow'

export default {
  components: { ItemRow },
  data: function () {
    return {
      items: null,
      terms: null,
      paging: null,
      errors: null,
      queryParams: {
        active: null,
        complete: null,
        keywords: null,
        terms: []
      }
    }
  },
  mounted: function () {
    this.reloadTerms()
    this.reloadItems()
  },
  methods: {
    reloadTerms () {
      termsApi.getAll().then(terms => { this.terms = terms })
    },
    reloadItems () {
      itemsApi.getAll().then(this.update)
    },
    submitQuery () {
      itemsApi.findItems(this.queryParams).then(this.update)
    },
    navigateTo (pageUrl) {
      itemsApi.getPage(pageUrl).then(this.update)
    },
    removeItem (item) {
      console.log(`Item ${item.directory} removed`)
      Vue.delete(this.items, item.directory)
    },
    setItem (item) {
      console.log(`Setting item ${item.directory}`)
      this.items[item.directory] = item
    },
    setErrors (errors) {
      this.errors = errors
    },
    // TODO: something cleaner
    update ({ items, paging }) {
      this.items = items
      this.paging = paging
    }
  }
}
</script>
