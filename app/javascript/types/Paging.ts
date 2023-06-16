export type Paging = PagingLinks & {
  currentPage: number,
  totalPages: number,
  itemsPerPage: number,
  currentPageItems: number,
  totalItems: number,
  fromItem: number,
  toItem: number
}

export type PagingLinks = {
  first?: URL,
  prev?: URL,
  next?: URL,
  last?: URL
}
