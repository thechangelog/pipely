# Get the changelog feed
GET {{proto}}://{{host}}/podcast/feed
HTTP 200 # expect OK response
[Asserts]
duration < 1000 # ensure that it loads sub 1s when cache is cold...
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

# Get the changelog feed AGAIN
GET {{proto}}://{{host}}/podcast/feed
[Options]
HTTP 200 # expect OK response
[Asserts]
duration < 500 # ensure that it loads sub 500ms when cached...
header "x-cache" == "HIT" # served from cache
header "x-cache-hits" toInt > 0 # served from cache
