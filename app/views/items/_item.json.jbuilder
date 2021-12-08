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
  # synthetic attributes
  :status
)
json.created_at(I18n.l(item.created_at, format: :xshort))
json.updated_at(I18n.l(item.updated_at, format: :xshort))
json.url item_url(item, format: :json)
