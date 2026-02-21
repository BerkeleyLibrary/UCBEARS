json.success(false)
json.error do
  json.code(Rack::Utils.status_code(local_assigns[:status]))
  json.errors do
    json.array!(local_assigns[:errors]) do |error|
      json.type error.type
      json.attribute error.attribute
      json.message error.full_message
      json.details error.details
    end
  end
end
