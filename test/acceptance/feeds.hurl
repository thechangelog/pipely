GET {{proto}}://{{host}}/rss
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

# Get the changelog feed
GET {{proto}}://{{host}}/podcast/feed?hurl=true
HTTP 200 # expect OK response
[Asserts]
duration < 1000 # ensure that it loads sub 1s when cache is cold...
header "cf-ray" exists # served from Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "cache-status" contains "region=" # region that served this request
header "cache-status" contains "origin=" # origin that served this request
header "cache-status" contains "ttl=" # ttl is set
header "cache-status" contains "grace=" # grace is set
header "cache-status" contains "keep=" # keep is set
header "cache-status" contains "storage=" # storage is set

# Get the changelog feed AGAIN
GET {{proto}}://{{host}}/podcast/feed?hurl=true
[Options]
delay: {{delay_ms}} # wait more than TTL so that it becomes stale
HTTP 200 # expect OK response
[Asserts]
duration < 500 # ensure that it loads sub 500ms when cached...
header "cache-status" contains "hit" # served from cache
header "cache-status" contains "stale" # will need to be refreshed from origin
header "age" toInt >= {{delay_s}} # has been stored in cache for MORE than TTL

# Get the changelog feed ONE MORE TIME
GET {{proto}}://{{host}}/podcast/feed?hurl=true
[Options]
delay: 5s # wait a bit so that it refreshes from origin
HTTP 200 # expect OK response
[Asserts]
duration < 500 # ensure that it loads sub 500ms when cached...
header "cache-status" contains "hit" # served from cache
header "cache-status" contains "storage.memory" # cached in memory
header "cache-status" not contains "stale" # not stale
header "age" toInt <= {{delay_s}} # has been stored in cache LESS than TTL

# Purge the changelog feed
PURGE {{proto}}://{{host}}/podcast/feed?hurl=true
Purge-Token: {{purge_token}}
HTTP 200 # expect OK response
[Asserts]
header "x-varnish" exists # served by Varnish
header "cache-status" contains "synth" # synthetic response

# Get the changelog feed after PURGE
GET {{proto}}://{{host}}/podcast/feed?hurl=true
HTTP 200 # expect OK response
[Asserts]
header "via" matches /[vV]arnish/ # served via Varnish
header "cache-status" contains "miss" # fresh after purge

GET {{proto}}://{{host}}/podcast/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/gotime/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/master/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/jsparty/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/shipit/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/news/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/brainscience/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/founderstalk/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/interviews/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/feed/
[Options]
skip: true
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/rfc/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/spotlight/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/afk/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/posts/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{proto}}://{{host}}/plusplus/xae9heiphohtupha1Ahha3aexoo0oo4W/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML
