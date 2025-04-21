# Get the admin homepage
GET {{host}}/admin
[Options]
repeat: 2 # repeat so that we confirm caching behaviour
HTTP 302 # expect found redirect
[Asserts]
header "fly-request-id" exists # served by Fly
header "via" matches /[vV]arnish/ # served via Varnish
header "location" == "/" # redirect to homepage
header "age" == "0" # NOT stored in cache
header "cache-status" contains "hits=0" # double-check that it's NOT stored in cache
header "cache-status" contains "miss" # NOT served from cache
