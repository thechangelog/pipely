# Get a static asset
GET {{proto}}://{{host}}/friends/73-pipely-tech.jpg?hurl=true
Host: {{assets_host}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "image/jpeg" # expect JPG
header "access-control-allow-origin" contains "*" # CORS
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works

# Purge the static asset
PURGE {{proto}}://{{host}}/friends/73-pipely-tech.jpg?purge=true
Host: {{assets_host}}
Purge-Token: {{purge_token}}
HTTP 200 # expect OK response
[Asserts]
header "x-varnish" exists # served by Varnish
header "cache-status" contains "synth" # synthetic response

# Get the static asset after PURGE
GET {{proto}}://{{host}}/friends/73-pipely-tech.jpg?purge=true
Host: {{assets_host}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "image/jpeg" # expect JPG
header "access-control-allow-origin" contains "*" # CORS
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "cache-status" contains "miss" # fresh after purge

GET {{proto}}://{{host}}/static/images/podcasts/podcast-original-f16d0363067166f241d080ee2e2d4a28.png
Host: {{assets_host}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "image/png" # expect PNG
header "access-control-allow-origin" contains "*" # CORS
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works

HEAD {{proto}}://{{host}}/static/images/podcasts/podcast-original-f16d0363067166f241d080ee2e2d4a28.png
Host: {{assets_host}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "image/png" # expect PNG
header "access-control-allow-origin" contains "*" # CORS
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works

POST {{proto}}://{{host}}/static/images/podcasts/podcast-original-f16d0363067166f241d080ee2e2d4a28.png
Host: {{assets_host}}
HTTP 405 # expect method not allowed

GET {{proto}}://{{host}}/static/css/email-5690e09e20c0b25fefebbc5049362b39.css
Host: {{assets_host}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "text/css" # expect CSS
header "access-control-allow-origin" contains "*" # CORS
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works

GET {{proto}}://{{host}}/uploads/news/140/changelog-news-140.mp3
Host: {{assets_host}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "audio/mpeg" # expect MP3
header "access-control-allow-origin" contains "*" # CORS
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
bytes count == 8575592 # full file size is correct

# Request first mp3 chunk
GET {{proto}}://{{host}}/uploads/news/140/changelog-news-140.mp3
Range: bytes=0-1023
Host: {{assets_host}}
HTTP 206 # expect partial content response
[Asserts]
header "content-type" contains "audio/mpeg" # expect MP3
header "access-control-allow-origin" contains "*" # CORS
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "cache-status" contains "storage.disk" # cached on disk
bytes count == 1024 # first chunk size is correct

# Request middle mp3 chunk
GET {{proto}}://{{host}}/uploads/news/140/changelog-news-140.mp3
Range: bytes=1024-2047
Host: {{assets_host}}
HTTP 206 # expect partial content response
[Asserts]
header "content-type" contains "audio/mpeg" # expect MP3
header "content-range" contains "bytes 1024-2047/8575592" # range response
header "access-control-allow-origin" contains "*" # CORS
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "cache-status" contains "storage.disk" # cached on disk
bytes count == 1024 # middle chunk size is correct

# Request end mp3 chunk
GET {{proto}}://{{host}}/uploads/news/140/changelog-news-140.mp3
Range: bytes=-1024
Host: {{assets_host}}
HTTP 206 # expect partial content response
[Asserts]
header "content-type" contains "audio/mpeg" # expect MP3
header "content-range" contains "bytes 8574568-8575591/8575592" # range response
header "access-control-allow-origin" contains "*" # CORS
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "cache-status" contains "storage.disk" # cached on disk
bytes count == 1024 # last chunk size is correct
