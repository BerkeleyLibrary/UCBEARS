json.extract!(
  term,
  :id,
  :name,
  :start_date,
  :end_date
)
json.item_count term.items.count
