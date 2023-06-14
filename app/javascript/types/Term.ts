export type Term = TermEdit & {
  id: number | string,
  url: string,
  created_at: string,
  updated_at: string
  current: boolean,
  item_count: number,
}

export type TermEdit = {
  name: string,
  default_term: boolean,
  start_date: string,
  end_date: string,
}
