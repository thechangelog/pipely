# GET the index page
GET {{proto}}://{{host}}?hurl=true
Host: {{nightly_host}}
HTTP 200 # expect OK response
[Asserts]
duration < 1000 # ensure that it loads sub 1s when cache is cold...
header "fly-request-id" exists # served by Fly
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "cache-status" contains "region=" # region that served this request
header "cache-status" contains "origin=" # origin that served this request
header "cache-status" contains "ttl=" # ttl is set
header "cache-status" contains "grace=" # grace is set
header "cache-status" contains "keep=" # keep is set
header "cache-status" contains "storage=" # storage is set

# GET the index page AGAIN
GET {{proto}}://{{host}}?hurl=true
Host: {{nightly_host}}
HTTP 200 # expect OK response
[Asserts]
duration < 100 # ensure that it loads sub 100ms when cached...
header "fly-request-id" exists # served by Fly.io
header "via" matches /[vV]arnish/ # served via Varnish
header "cache-status" contains "hit" # definitely served from cache
header "cache-status" contains "storage.memory" # cached in memory

# GET a specific page
GET {{proto}}://{{host}}/2025/12/30/?hurl=true
Host: {{nightly_host}}
HTTP 200 # expect OK response
[Asserts]
duration < 1000 # ensure that it loads sub 1s when cache is cold...
header "fly-request-id" exists # served by Fly.io
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "cache-status" contains "region=" # region that served this request
header "cache-status" contains "origin=" # origin that served this request
header "cache-status" contains "ttl=" # ttl is set
header "cache-status" contains "grace=" # grace is set
header "cache-status" contains "keep=" # keep is set
header "cache-status" contains "storage=" # storage is set
body matches "Changelog Nightly.+2025-12-30"

# GET a static asset
GET {{proto}}://{{host}}/images/logo-night.png?hurl=true
Host: {{nightly_host}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "image/png" # expect PNG
header "access-control-allow-origin" contains "*" # CORS
header "fly-request-id" exists # served by Fly.io
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works

# HEAD the same static asset
HEAD {{proto}}://{{host}}/images/logo-night.png?hurl=true
Host: {{nightly_host}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "image/png" # expect PNG
header "access-control-allow-origin" contains "*" # CORS
header "fly-request-id" exists # served by Fly.io
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "cache-status" contains "storage.memory" # cached in memory