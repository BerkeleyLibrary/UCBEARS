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
  :updated_at,
  # synthetic attributes
  :status
)
json.url item_url(item, format: :json)
