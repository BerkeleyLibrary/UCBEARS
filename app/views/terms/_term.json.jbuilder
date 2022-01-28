json.extract!(
  term,
  :id,
  :name,
)
# TODO: just store term start/end date as local midnight timestamp
json.start_date term.start_date.to_time
json.end_date term.end_date.to_time
json.item_count term.items.count
json.url term_url(term, format: :json)
