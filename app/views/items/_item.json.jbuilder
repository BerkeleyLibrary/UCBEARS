json.extract!(
  item,
  :id,
  :directory,
  :title,
  :author,
  :copies,
  :active,
  :publisher,
  :physical_desc,
  :created_at,
  :updated_at
)
json.complete(item.complete?)
json.reason_incomplete(item.reason_incomplete || (Item::MSG_ZERO_COPIES if item.copies < 1))
json.url item_url(item, format: :json)
json.edit_url lending_edit_url(directory: item.directory)
json.show_url lending_show_url(directory: item.directory)
json.view_url lending_view_url(directory: item.directory)
json.terms item.terms, partial: 'terms/term', as: :term
