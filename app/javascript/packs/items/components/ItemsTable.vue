<template>
  <table class="items">
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

export default {
  data: function () {
    return {
      items: null,
      links: null
    }
  },
  mounted: function () {
    const itemApiUrl = new URL('/items.json', window.location)
    axios.get(itemApiUrl.toString(), {headers: {'Accept': 'application/json'}})
    .then(response => {
      let items = response.data
      console.log(items)

      let headers = response.headers
      console.log(headers)

      let link = Link.parse(headers['link'])
      console.log(link)

      let links = {}
      for (const rel of ['first', 'prev', 'next', 'last']) {
        if (link.has('rel', rel)) {
          links[rel] = link.get('rel', rel)[0].uri
        }
      }
      console.log(links)

      this.items = items
      this.links = links
    })
    .catch(error => console.log(error))
  }
}
</script>