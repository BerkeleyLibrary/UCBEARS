<template>
  <section class="items-table">
    <!-- TODO: extract this to its own component -->
    <nav v-if="links">
      <ul>
        <li>
          <a v-if="links.first && links.currentPage !== 1" @click="loadItems(links.first)" href="#" rel="first" title="First page">≪</a>
          <template v-else>≪</template>
        </li>
        <li>
          <a v-if="links.prev && links.currentPage > 1" @click="loadItems(links.prev)" href="#" rel="prev" title="Previous page">&lt;</a>
          <template v-else>&lt;</template>
        </li>
        <li>
          Page {{ links.currentPage }} of {{ links.totalPages }}
        </li>
        <li>
          <a v-if="links.next && links.currentPage < links.totalPages" @click="loadItems(links.next)" href="#" rel="next" title="Next page">&gt;</a>
          <template v-else>&gt;</template>
        </li>
        <li>
          <a v-if="links.last && links.currentPage !== links.totalPages" @click="loadItems(links.last)" href="#" rel="last" title="Last page">≫</a>
          <template v-else>≫</template>
        </li>
      </ul>
    </nav>
    <table>
      <thead>
      <tr>
        <th>Title</th>
        <th>Author</th>
        <th>Publisher</th>
        <th>Physical Description</th>
        <th>Status</th>
        <th>Created</th>
        <th>Updated</th>
      </tr>
      </thead>
      <tbody>
      <tr v-for="item in items" :key="item.directory">
        <td> {{ item.title }}</td>
        <td> {{ item.author }}</td>
        <td> {{ item.publisher }}</td>
        <td> {{ item.physical_desc }}</td>
        <td> {{ item.status }}</td>
        <td> {{ item.created_at }}</td>
        <td> {{ item.updated_at }}</td>
      </tr>
      </tbody>
    </table>
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

function linksFromLinkHeader (response) {
  let headers = response.headers
  console.log(headers)

  let link = Link.parse(headers['link'])
  console.log(link)

  let links = {
    currentPage: parseInt(headers['current-page']) || null,
    totalPages: parseInt(headers['total-pages']) || null
  }

  for (const rel of ['first', 'prev', 'next', 'last']) {
    if (link.has('rel', rel)) {
      links[rel] = link.get('rel', rel)[0].uri
    }
  }
  console.log(links)
  return links
}

export default {
  data: function () {
    return {
      items: null,
      links: null
    }
  },
  methods: {
    loadItems: function (itemApiUrl) {
      axios.get(itemApiUrl.toString(), {headers: {'Accept': 'application/json'}})
      .then(response => {
        this.items = response.data
        this.links = linksFromLinkHeader(response)
      }).catch(error => console.log(error))
    }
  },
  mounted: function () {
    const itemApiUrl = new URL('/items.json', window.location)
    this.loadItems(itemApiUrl)
  }
}
</script>