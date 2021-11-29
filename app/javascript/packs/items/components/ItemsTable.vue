<template>
  <table class="items">
    <thead>
    <tr>
      <th>Title</th>
      <th>Author</th>
      <th>Publication Metadata</th>
      <th>Status</th>
    </tr>
    </thead>
    <tbody>
    <tr v-for="item in items" :key="item.directory">
      <td> {{ item.title }}</td>
      <td> {{ item.author }}</td>
      <td> {{ item.status }}</td>
    </tr>
    </tbody>
  </table>
</template>

<script>
import axios from 'axios'

export default {
  data: function () {
    return {
      items: null
    }
  },
  mounted: function () {
    const itemApiUrl = new URL('/items.json', window.location)
    axios.get(itemApiUrl.toString(), {headers: {'Accept': 'application/json'}})
    .then(response => this.items = response.data)
    .catch(error => console.log(error))
  }
}
</script>