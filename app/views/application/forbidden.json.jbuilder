error = { location: request.original_fullpath }

if defined?(message)
  msg = message
  error[:details] = msg
else
  msg = 'Forbidden'
end

json.success(false)
json.error do
  json.code(403)
  json.message(msg)
  json.errors([error])
end
