json.success(false)
json.error do
  json.code(Rack::Utils.status_code(local_assigns[:status]))
  json.message(local_assigns[:message])
  json.errors([{ location: request.original_fullpath }])
end
