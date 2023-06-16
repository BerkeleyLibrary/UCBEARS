import { Term } from "./Term";

export type ItemId = string | number;

export type Item = ItemEdit & {
  id: ItemId,
  directory: string,
  title?: string,
  author?: string,
  publisher?: string,
  physical_desc?: string,

  complete: boolean,
  reason_incomplete?: string,

  created_at: string,
  updated_at: string,

  url: string,
  edit_url: string,
  show_url: string,
  view_url: string,
}

export type ItemEdit = {
  copies: number,
  active: boolean,
  terms: Term[]
}
