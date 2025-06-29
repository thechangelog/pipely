# Get a static asset
GET {{host}}/friends/73-pipely-tech.jpg?hurl=true
Host: {{assets_host}}
Content-Type: image/jpeg # expect JPG
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works

# Purge the static asset
PURGE {{host}}/friends/73-pipely-tech.jpg?purge=true
Host: {{assets_host}}
Purge-Token: {{purge_token}}
HTTP 200 # expect OK response
[Asserts]
header "x-varnish" exists # served by Varnish
header "cache-status" contains "synth" # synthetic response

# Get the static asset after PURGE
GET {{host}}/friends/73-pipely-tech.jpg?purge=true
Host: {{assets_host}}
Content-Type: image/jpeg # expect JPG
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "cache-status" contains "miss" # fresh after purge
