# Get the homepage
GET {{host}}
HTTP 200 # expect OK response
[Asserts]
duration < 1000 # ensure that it loads sub 1s when cache is cold...
header "fly-request-id" exists # served by Fly
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works

# Get the homepage AGAIN
GET {{host}}
HTTP 200 # expect OK response
[Asserts]
duration < 100 # ensure that it loads sub 100ms when cached...
header "x-cache" == "HIT" # double-check that it's NOT stored in cache
header "x-cache-hits" toInt > 0 # served from cache
