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
header "cache-status" contains "keep=" # keep is set
header "cache-status" contains "storage=" # storage is set

# Test the assets_host
GET http://{{host}}/friends/73-pipely-tech.jpg?hurl=true&https
Host: {{assets_host}}
# we only add the X-Forwarded-Proto header to test local behaviour.
# Fastly ignores it.
# Fly.io overwrites this at a platform level.
X-Forwarded-Proto: https
Content-Type: image/jpeg # expect JPG
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
