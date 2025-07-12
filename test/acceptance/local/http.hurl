# We are simulating the Fly.io behaviour locally
GET http://{{host}}/
X-Forwarded-Proto: https
HTTP 200
[Asserts]
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "cache-status" contains "region=" # region that served this request
header "cache-status" contains "origin=" # origin that served this request
header "cache-status" contains "ttl=" # ttl is set
header "cache-status" contains "grace=" # grace is set
