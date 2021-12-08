json.extract!(
  item,
  :id,
  :directory,
  :title,
  :author,
  :copies,
  :active,
  :publisher,
  :physical_desc
)
json.created_at(I18n.l(item.created_at, format: :xshort))
json.updated_at(I18n.l(item.updated_at, format: :xshort))
json.complete(item.complete?)
json.reason_inactive(item.reason_incomplete || (Item::MSG_ZERO_COPIES if item.copies < 1))
json.url item_url(item, format: :json)
