import { Item } from "./Item";
import { Paging } from "./Paging";

export type PagedItems = {
  paging: Paging,
  items: ItemsByDirectory
}

export type ItemsByDirectory = { [key: string]: Item }
