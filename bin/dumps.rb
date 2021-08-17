#!/usr/bin/env ruby

require 'yaml'

patrons = YAML.load_file('test/fixtures/cassettes/patrons.yml')

patron_id_regex = %r{https://dev-oskicatp.berkeley.edu:54620/PATRONAPI/([^/]+)/dump}
patrons["http_interactions"].each do | http_interaction |
  uri = http_interaction['request']['uri']
  patron_id = patron_id_regex.match(uri)[1]
  body = http_interaction['response']['body']['string']
  puts "spec/data/patrons/#{patron_id}.txt"
  File.open("spec/data/patrons/#{patron_id}.txt", 'w') do |f|
    f.write(body)
  end
end
