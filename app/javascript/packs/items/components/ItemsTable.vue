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

    <table>
      <thead>
        <tr>
          <th>Title</th>
          <th>Author</th>
          <th>Publisher</th>
          <th>Physical Description</th>
          <th>Copies</th>
          <th>Active</th>
          <th>Complete</th>
          <th>Created</th>
          <th>Updated</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="item in items"
          :key="item.directory"
          class="item"
        >
          <td>{{ item.title }}</td>
          <td>{{ item.author }}</td>
          <td>{{ item.publisher }}</td>
          <td>{{ item.physical_desc }}</td>
          <td class="control">
            <input
              v-model.number.lazy="item.copies"
              type="number"
              @change="updateItem(item)"
            >
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
          <td class="date">
            {{ item.created_at }}
          </td>
          <td class="date">
            {{ item.updated_at }}
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
      links: null,
      errors: null
    }
  },
  mounted: function () {
    const itemApiUrl = new URL('/items.json', window.location)
    this.loadItems(itemApiUrl)
  },
  methods: {
    loadItems (itemApiUrl) {
      axios.get(itemApiUrl.toString(), { headers: { Accept: 'application/json' } })
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
