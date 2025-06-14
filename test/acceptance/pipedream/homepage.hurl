# Get the homepage
GET {{host}}
HTTP 200 # expect OK response
[Asserts]
duration < 500 # ensure that it loads sub 500ms when cache is cold...
header "fly-request-id" exists # served by Fly
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "cache-status" contains "region=" # region that served this request
header "cache-status" contains "origin=" # origin that served this request
header "cache-status" contains "ttl=" # ttl is set
header "cache-status" contains "grace=" # grace is set

# Get the homepage AGAIN
GET {{host}}
HTTP 200 # expect OK response
[Asserts]
duration < 100 # ensure that it loads sub 100ms when cached...
header "fly-request-id" exists # served by Fly
header "via" matches /[vV]arnish/ # served via Varnish
header "cache-status" contains "hit" # definitely served from cache

# Purge the homepage
PURGE {{host}}
HTTP 200 # expect OK response
[Asserts]
header "fly-request-id" not exists # NOT served by Fly
header "server" == "Varnish" # served by Varnish

# Get the homepage after PURGE
GET {{host}}
HTTP 200 # expect OK response
[Asserts]
header "fly-request-id" exists # served by Fly
header "via" matches /[vV]arnish/ # served via Varnish
header "cache-status" contains "miss" # fresh after purge
