<template>
  <section class="items-table">
    <aside
      v-if="errors"
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

    <form class="item-facets">
      <fieldset>
        <legend>Term</legend>

        <template v-for="term in terms">
          <!-- TODO: add term selection UI -->
          <label>{{ term.name }}</label>
        </template>
      </fieldset>

      <fieldset>
        <legend>Status</legend>

        <input id="itemQuery-active" type="checkbox" v-model="itemQuery.active" true-value="true" :false-value="null" @change="reload()">
        <label for="itemQuery-active">Active only</label>

        <input id="itemQuery-inactive" type="checkbox" v-model="itemQuery.active" true-value="false" :false-value="null" @change="reload()">
        <label for="itemQuery-active">Inactive only</label>
      </fieldset>

      <fieldset>
        <legend>Completeness</legend>

        <input id="itemQuery-complete" type="checkbox" v-model="itemQuery.complete" true-value="true" :false-value="null" @change="reload()">
        <label for="itemQuery-complete">Complete only</label>

        <input id="itemQuery-incomplete" type="checkbox" v-model="itemQuery.complete" true-value="false" :false-value="null" @change="reload()">
        <label for="itemQuery-complete">Incomplete only</label>
      </fieldset>
    </form>

    <table>
      <thead>
        <tr>
          <th>Edit</th>
          <th>Title</th>
          <th>Author</th>
          <th>Publisher</th>
          <th>Physical Description</th>
          <th>Updated</th>
          <th>Complete</th>
          <th>Copies</th>
          <th>Term</th>
          <th>Active</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="item in items"
          :key="item.directory"
          class="item"
        >
          <td class="control">
            <!-- TODO: style this properly -->
            <a :href="item.edit_url"><img src="/assets/icons/edit.svg" :alt="`Edit '${item.title}'`" class="action"></a>
          </td>
          <td>{{ item.title }}</td>
          <td>{{ item.author }}</td>
          <td>{{ item.publisher }}</td>
          <td>{{ item.physical_desc }}</td>
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
            {{ item.terms && item.terms.join(', ') }}
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
        </tr>
      </tbody>
    </table>

    <!-- TODO: extract this to its own component -->
    <nav
      v-if="links"
      class="pagination"
    >
      <ul>
        <li>
          <a
            v-if="links.first && links.currentPage !== 1"
            href="#"
            rel="first"
            title="First page"
            @click="loadItems(links.first)"
          >≪</a>
          <template v-else>
            ≪
          </template>
        </li>
        <li>
          <a
            v-if="links.prev && links.currentPage > 1"
            href="#"
            rel="prev"
            title="Previous page"
            @click="loadItems(links.prev)"
          >&lt;</a>
          <template v-else>
            &lt;
          </template>
        </li>
        <li>
          Page {{ links.currentPage }} of {{ links.totalPages }}
        </li>
        <li>
          <a
            v-if="links.next && links.currentPage < links.totalPages"
            href="#"
            rel="next"
            title="Next page"
            @click="loadItems(links.next)"
          >&gt;</a>
          <template v-else>
            &gt;
          </template>
        </li>
        <li>
          <a
            v-if="links.last && links.currentPage !== links.totalPages"
            href="#"
            rel="last"
            title="Last page"
            @click="loadItems(links.last)"
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
import Link from 'http-link-header'

/*
# Pagy::DEFAULT[:headers] = { page: 'Current-Page',
#                            items: 'Page-Items',
#                            count: 'Total-Count',
#                            pages: 'Total-Pages' }     # default

 */

function patchItem (item) {
  console.log(`Saving item ${item.directory}`)
  return axios.patch(item.url, {
    item: {
      title: item.title,
      author: item.author,
      copies: item.copies,
      active: item.active,
      publisher: item.publisher,
      physical_desc: item.physical_desc
    }
  })
    .then(response => {
      console.log(`Item ${item.directory} saved`)
      return response.data
    })
}

function getItem (itemUrl) {
  return axios.get(itemUrl).then(response => response.data)
}

function itemsByDirectory (itemArray) {
  const items = {}
  for (const item of itemArray) {
    items[item.directory] = item
  }
  return items
}

function linksFromHeaders (headers) {
  const currentPageHeader = headers['current-page']
  const totalPagesHeader = headers['total-pages']
  const links = {
    currentPage: parseInt(currentPageHeader) || null,
    totalPages: parseInt(totalPagesHeader) || null
  }

  const linkHeader = headers.link
  const parsedLinks = Link.parse(linkHeader)

  for (const rel of ['first', 'prev', 'next', 'last']) {
    if (parsedLinks.has('rel', rel)) {
      links[rel] = parsedLinks.get('rel', rel)[0].uri
    }
  }
  return links
}

export default {
  data: function () {
    return {
      items: null,
      terms: null,
      links: null,
      errors: null,
      itemQuery: {
        active: null,
        complete: null
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
      // TODO: Merge itemQuery params instead of letting axios append them, or else set pagination params explicitly
      axios.get(itemApiUrl.toString(), { headers: { Accept: 'application/json' }, params: this.itemQuery })
        .then(response => {
          this.items = itemsByDirectory(response.data)
          this.links = linksFromHeaders(response.headers)
        }).catch(error => console.log(error))
    },
    updateItem (item) {
      this.setErrors(null)

      patchItem(item)
        .then(item => this.setItem(item))
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
      getItem(item.url).then(item => this.setItem(item))
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
