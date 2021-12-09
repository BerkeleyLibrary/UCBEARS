<template>
  <section class="items-table">
    <aside class="flash" v-if="errors">
      <template v-for="(error, index) in errors">
        <input type="checkbox" class="flash-dismiss" checked :id="`flash-dismiss-items-table-${index}`" v-on:change="errors.splice(index, 1)"        >
        <div class="flash alert">
          <label class="flash-dismiss-label" :for="`flash-dismiss-items-table-${index}`">
            <img src="/assets/icons/times-circle.svg" class="flash-dismiss-icon"/>
          </label>
          <p class="flash">{{ error }}</p>
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
      <tr v-for="item in items" :key="item.directory" class="item">
        <td>{{ item.title }}</td>
        <td>{{ item.author }}</td>
        <td>{{ item.publisher }}</td>
        <td>{{ item.physical_desc }}</td>
        <td class="control"><input type="number" v-model.number.lazy="item.copies" v-on:change="updateItem(item)"></td>
        <td class="control">
          <input type="checkbox" v-model.lazy="item.active" v-on:change="updateItem(item)"
                 :disabled="!!item.reason_inactive" :title="item.reason_inactive">
        </td>
        <td class="date">{{ item.created_at }}</td>
        <td class="date">{{ item.updated_at }}</td>
      </tr>
      </tbody>
    </table>

    <!-- TODO: extract this to its own component -->
    <nav class="pagination" v-if="links">
      <ul>
        <li>
          <a v-if="links.first && links.currentPage !== 1" @click="loadItems(links.first)" href="#" rel="first"
             title="First page">≪</a>
          <template v-else>≪</template>
        </li>
        <li>
          <a v-if="links.prev && links.currentPage > 1" @click="loadItems(links.prev)" href="#" rel="prev"
             title="Previous page">&lt;</a>
          <template v-else>&lt;</template>
        </li>
        <li>
          Page {{ links.currentPage }} of {{ links.totalPages }}
        </li>
        <li>
          <a v-if="links.next && links.currentPage < links.totalPages" @click="loadItems(links.next)" href="#"
             rel="next" title="Next page">&gt;</a>
          <template v-else>&gt;</template>
        </li>
        <li>
          <a v-if="links.last && links.currentPage !== links.totalPages" @click="loadItems(links.last)" href="#"
             rel="last" title="Last page">≫</a>
          <template v-else>≫</template>
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

function getItem (item_url) {
  return axios.get(item_url).then(response => response.data)
}

function itemsByDirectory (itemArray) {
  const items = {}
  for (const item of itemArray) {
    items[item.directory] = item
  }
  return items
}

function linksFromHeaders (headers) {
  let currentPageHeader = headers['current-page']
  let totalPagesHeader = headers['total-pages']
  let links = {
    currentPage: parseInt(currentPageHeader) || null,
    totalPages: parseInt(totalPagesHeader) || null
  }

  let linkHeader = headers['link']
  let parsedLinks = Link.parse(linkHeader)

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
  methods: {
    loadItems (itemApiUrl) {
      axios.get(itemApiUrl.toString(), {headers: {'Accept': 'application/json'}})
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
          let errors = error.response.data
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
  },
  mounted: function () {
    const itemApiUrl = new URL('/items.json', window.location)
    this.loadItems(itemApiUrl)
  }
}
</script>
