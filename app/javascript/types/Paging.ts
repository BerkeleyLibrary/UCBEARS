export type Paging = {
  currentPage: number,
  totalPages: number,
  itemsPerPage: number,
  currentPageItems: number,
  totalItems: number,
  fromItem: number,
  toItem: number
  first?: URL,
  prev?: URL,
  next?: URL,
  last?: URL
}
