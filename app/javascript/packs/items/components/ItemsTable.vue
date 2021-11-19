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
      <td> {{ item.pub_metadata }}</td>
      <td> {{ item.status }}</td>
    </tr>
    </tbody>
  </table>
</template>

<script>
module.exports = {
  data: function () {
    return {
      
    }
  }
}
</script>