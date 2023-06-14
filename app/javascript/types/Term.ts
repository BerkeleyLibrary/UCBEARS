export type TermId = number | string;

export type Term = TermEdit & {
  id: TermId,
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
