GET {{proto}}://{{host}}/health
HTTP 204 # expect No Content response
[Asserts]
header "x-varnish" exists # served by Varnish
header "cache-status" contains "region" # contains region info (a.k.a. server_datacentre)
header "cache-status" contains "synth" # never cached

GET {{proto}}://{{host}}/app_health
HTTP 200 # expect OK response
[Asserts]
header "via" matches /[vV]arnish/ # served via Varnish
header "cache-status" contains "region" # contains region info (a.k.a. server_datacentre)
header "cache-status" contains "origin=app" # served by app backend
header "cache-status" contains "bypass" # never cached

GET {{proto}}://{{host}}/feeds_health
HTTP 200 # expect OK response
[Asserts]
header "via" matches /[vV]arnish/ # served via Varnish
header "cache-status" contains "region" # contains region info (a.k.a. server_datacentre)
header "cache-status" contains "origin=feeds" # served by feeds backend
header "cache-status" contains "bypass" # never cached

GET {{proto}}://{{host}}/assets_health
HTTP 200 # expect OK response
[Asserts]
header "via" matches /[vV]arnish/ # served via Varnish
header "cache-status" contains "region" # contains region info (a.k.a. server_datacentre)
header "cache-status" contains "origin=assets" # served by feeds backend
header "cache-status" contains "bypass" # never cached
