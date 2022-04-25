json.extract!(
  term,
  :id,
  :name,
  :created_at,
  :updated_at
)
# TODO: just store term start/end date as local midnight timestamp
json.start_date term.start_date.in_time_zone.iso8601
json.end_date term.end_date.in_time_zone.iso8601
json.item_count ItemsTerm.where(term_id: term.id).count
json.url term_url(term, format: :json)
json.current term.current?
json.default_term term.default?
