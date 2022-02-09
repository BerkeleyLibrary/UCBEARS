json.success(false)
json.error do
  json.code(Rack::Utils.status_code(status))
  json.message(message)
  json.errors([{ location: request.original_fullpath }])
end
