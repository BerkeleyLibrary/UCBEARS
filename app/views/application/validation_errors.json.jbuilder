json.success(false)
json.error do
  json.code(Rack::Utils.status_code(status))
  json.errors do
    json.array!(errors) do |error|
      json.type error.type
      json.attribute error.attribute
      json.message error.full_message
      json.details error.details
    end
  end
end
