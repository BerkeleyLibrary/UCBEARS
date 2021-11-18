json.extract! item, :id, :directory, :title, :author, :copies, :active, :publisher, :physical_desc, :created_at, :updated_at
json.url item_url(item, format: :json)
