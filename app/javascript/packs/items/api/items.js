import axios from 'axios'

export default {
  get (itemUrl) {
    return axios.get(itemUrl).then(response => response.data)
  },

  update (item) {
    console.log(`Saving item ${item.directory} (${item.id})`)
    return axios.patch(item.url, {
      item: {
        title: item.title,
        author: item.author,
        copies: item.copies,
        active: item.active,
        publisher: item.publisher,
        physical_desc: item.physical_desc,
        term_ids: item.terms.map(t => t.id)
      }
    })
      .then(response => response.data)
  },

  destroy (item) {
    console.log(`Deleting item ${item.directory} (${item.id})`)
    return axios.delete(item.url).then(response => response.data)
  },

  byDirectory (items) {
    // TODO: should this be a Map?
    return Object.fromEntries(items.map(it => [it.directory, it]))
  }
}
