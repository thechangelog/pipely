# Get a static asset
GET {{host}}/friends/73-pipely-tech.jpg
Host: {{assets_host}}
Content-Type: image/jpeg # expect JPG
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works

# Purge the static asset
PURGE {{host}}/friends/73-pipely-tech.jpg
Host: {{assets_host}}
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" not exists # NOT served from Cloudflare
header "server" == "Varnish" # served by Varnish

# Get the static asset after PURGE
GET {{host}}/friends/73-pipely-tech.jpg
Host: {{assets_host}}
Content-Type: image/jpeg # expect JPG
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "cache-status" contains "miss" # fresh after purge
