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
        <input
          id="itemQuery-keywords"
          v-model="itemQuery.keywords"
          type="search"
          placeholder="Search by title, author, publisher, or physical description"
          @keydown.enter.prevent
          @keyup.enter="reload()"
        >
        <button type="button" class="primary" @click="$event.target.blur(); reload()">Go</button>
      </div>
    </form>

    <form class="item-facets">
      <fieldset>
        <legend>Term</legend>

        <template v-for="term in terms">
          <input :id="`term-${term.id}`" :key="`${term.id}-checkbox`" v-model="itemQuery.terms" type="checkbox" :value="term.name" @change="reload()">
          <label :key="`${term.id}-label`" :for="`term-${term.id}`">{{ term.name }}</label>
        </template>
      </fieldset>

      <fieldset>
        <legend>Status</legend>

        <input id="itemQuery-active" v-model="itemQuery.active" type="checkbox" true-value="true" :false-value="null" @change="reload()">
        <label for="itemQuery-active">Active only</label>

        <input id="itemQuery-inactive" v-model="itemQuery.active" type="checkbox" true-value="false" :false-value="null" @change="reload()">
        <label for="itemQuery-active">Inactive only</label>
      </fieldset>

      <fieldset>
        <legend>Complete?</legend>

        <input id="itemQuery-complete" v-model="itemQuery.complete" type="checkbox" true-value="true" :false-value="null" @change="reload()">
        <label for="itemQuery-complete">Complete only</label>

        <input id="itemQuery-incomplete" v-model="itemQuery.complete" type="checkbox" true-value="false" :false-value="null" @change="reload()">
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
        <tr
          v-for="item in items"
          :key="item.directory"
          class="item"
        >
          <td class="control">
            <a :href="item.edit_url" class="icon-link" target="_blank" :title="`Edit “${item.title}”`"><img src="/assets/icons/edit.svg" :alt="`Edit “${item.title}”`" class="action"></a>
          </td>
          <td>
            <p class="title">
              {{ item.title }}
            </p>
            <p class="author-name">
              {{ item.author }}
            </p>
            <p class="metadata">
              {{ item.publisher }}
              {{ item.physical_desc }}
            </p>
          </td>
          <td class="control">
            <a :href="item.show_url" class="icon-link" target="_blank" :title="`Admin view of “${item.title}”`"><img src="/assets/icons/eye.svg" :alt="`Admin view of “${item.title}”`" class="action"></a>
          </td>
          <td class="control">
            <a :href="item.view_url" class="icon-link" target="_blank" :title="`Permalink to “${item.title}” patron view`"><img src="/assets/icons/link.svg" :alt="`Permalink to “${item.title}” patron view`" class="action"></a>
          </td>
          <td class="date">{{ item.updated_at }}</td>
          <td v-if="item.complete" class="control">Yes</td>
          <td v-else :title="item.reason_inactive" class="control">No</td>
          <td class="control">
            <input
              v-model.number.lazy="item.copies"
              type="number"
              @change="updateItem(item)"
            >
          </td>
          <td>
            <ul>
              <li v-for="term in terms" :key="`${item.id}-term-${term.id}`">
                <input :id="`${item.id}-term-${term.id}`" v-model.lazy="item.terms" type="checkbox" :value="term" @change="updateItem(item)">
                <label :for="`${item.id}-term-${term.id}`">{{ term.name }}</label>
              </li>
            </ul>
          </td>
          <td class="control">
            <input
              v-model.lazy="item.active"
              type="checkbox"
              :disabled="!!item.reason_inactive"
              :title="item.reason_inactive"
              @change="updateItem(item)"
            >
          </td>
          <td class="control">
            <button class="delete" :disabled="item.complete" :title="item.complete ? 'Only incomplete items can be deleted.' : `Delete “${item.title}”`" @click="removeItem(item)">
              <img class="action" src="/assets/icons/trash-alt.svg">
            </button>
          </td>
        </tr>
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
            @click="loadItems(paging.first)"
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
            @click="loadItems(paging.prev)"
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
            @click="loadItems(paging.next)"
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
            @click="loadItems(paging.last)"
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
import axios from 'axios'
import Vue from 'vue'
import items from '../api/items'
import paging from '../api/paging'

export default {
  // TODO: use VueX
  data: function () {
    return {
      items: null,
      terms: null,
      paging: null,
      errors: null,
      itemQuery: {
        active: null,
        complete: null,
        keywords: null,
        terms: []
      }
    }
  },
  mounted: function () {
    this.reload()
  },
  methods: {
    reload () {
      const termsUrl = new URL('/terms.json', window.location)
      this.loadTerms(termsUrl)

      const itemApiUrl = new URL('/items.json', window.location)
      this.loadItems(itemApiUrl)
    },
    loadTerms (termApiUrl) {
      axios.get(termApiUrl.toString())
        .then(response => {
          this.terms = response.data
        }).catch(error => console.log(error))
    },
    loadItems (itemApiUrl) {
      // TODO: clean this up -- if it's a next/prev URL with query parameters we don't need to append params at all
      const searchParams = itemApiUrl.searchParams
      if (searchParams) {
        searchParams.delete('active')
        searchParams.delete('inactive')
        searchParams.delete('complete')
        searchParams.delete('incomplete')
        searchParams.delete('keywords')
        searchParams.delete('terms')
      }

      axios.get(itemApiUrl.toString(), { headers: { Accept: 'application/json' }, params: this.itemQuery })
        .then(response => {
          this.items = items.byDirectory(response.data)
          this.paging = paging.fromHeaders(response.headers)
        }).catch(error => console.log(error))
    },
    removeItem (item) {
      items.destroy(item)
        .then(() => {
          console.log(`Deleted item ${item.directory} (${item.id})`)
          Vue.delete(this.items, item.directory)
        }).catch(error => {
          console.log(error)
          if (error.response) {
            const errors = error.response.data
            console.log(`Error deleting item ${item.directory}: ${errors.join('; ')}`)
            this.setErrors(errors)
          } else {
            console.log(`Error deleting item ${item.directory}`)
          }
          this.refreshItem(item)
        })
    },
    updateItem (item) {
      this.setErrors(null)

      items.update(item)
        .then(item => {
          console.log(`Item ${item.directory} saved`)
          this.setItem(item)
        })
        .catch(error => {
          if (error.response) {
            const errors = error.response.data
            console.log(`Error saving item ${item.directory}: ${errors.join('; ')}`)
            this.setErrors(errors)
          } else {
            console.log(`Error saving item ${item.directory}`)
          }
          this.refreshItem(item)
        })
    },
    refreshItem (item) {
      items.get(item.url).then(item => this.setItem(item))
    },
    setItem (item) {
      this.items[item.directory] = item
    },
    setErrors (errors) {
      this.errors = errors
    }
  }
}
</script>
