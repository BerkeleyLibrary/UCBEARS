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

export default {
  data: function () {
    return {
      items: null
    }
  },
  mounted: function () {
    const itemApiUrl = new URL('/items.json', window.location)
    axios.get(itemApiUrl.toString(), {headers: {'Accept': 'application/json'}})
    .then(response => {
      console.log(response.data)
      return this.items = response.data
    })
    .catch(error => console.log(error))
  }
}
</script>