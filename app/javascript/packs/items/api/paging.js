import Link from 'http-link-header'

export default {
  fromHeaders (headers) {
    const paging = {
      currentPage: getInt(headers, 'current-page', 1),
      totalPages: getInt(headers, 'total-pages', 1),
      itemsPerPage: getInt(headers, 'page-items', 0),
      currentPageItems: getInt(headers, 'current-page-items', 0),
      totalItems: getInt(headers, 'total-count', 0)
    }
    paging.fromItem = ((paging.currentPage - 1) * paging.itemsPerPage) + 1
    paging.toItem = (paging.fromItem + paging.currentPageItems) - 1

    const linkHeader = headers.link
    if (!linkHeader) {
      return paging
    }

    const links = Link.parse(linkHeader)
    for (const rel of ['first', 'prev', 'next', 'last']) {
      if (links.has('rel', rel)) {
        const urlStr = links.get('rel', rel)[0].uri
        paging[rel] = new URL(urlStr)
      }
    }

    return paging
  }
}
function getInt (headers, name, defaultValue) {
  return parseInt(headers[name]) || defaultValue
}
