# Get the changelog feed
GET {{host}}/podcast/feed
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

# Get the changelog feed AGAIN
GET {{host}}/podcast/feed
[Options]
delay: {{delay_ms}} # wait more than TTL so that it becomes stale
HTTP 200 # expect OK response
[Asserts]
duration < 500 # ensure that it loads sub 500ms when cached...
header "cache-status" contains "hit" # served from cache
header "cache-status" contains "stale" # will need to be refreshed from origin
header "age" toInt > {{delay_s}} # has been stored in cache for MORE than TTL

# Get the changelog feed ONE MORE TIME
GET {{host}}/podcast/feed
[Options]
delay: 5s # wait a bit so that it refreshes from origin
HTTP 200 # expect OK response
[Asserts]
duration < 500 # ensure that it loads sub 500ms when cached...
header "cache-status" contains "hit" # served from cache
header "cache-status" not contains "stale" # not stale
header "age" toInt < {{delay_s}} # has been stored in cache LESS than TTL

# Purge the changelog feed
PURGE {{host}}/podcast/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" not exists # NOT served from Cloudflare
header "server" == "Varnish" # served by Varnish

# Get the changelog feed after PURGE
GET {{host}}/podcast/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served from Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "cache-status" contains "miss" # fresh after purge
