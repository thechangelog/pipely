GET https://{{host}}/news
Flyio-Debug: doit
Fly-Force-Region: {{region}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "text/html; charset=utf-8" # expect HTML
header "cache-status" contains "fly.dev" # origin is Fly.io
header "via" contains "Varnish" # served via Varnish
header "flyio-debug" exists # we have extra debug information
header "age" exists # cache age works
header "cache-status" contains {{region}} # region is correct
header "cache-status" contains "storage.memory" # cached in memory

GET https://{{host}}/podcast/feed
Flyio-Debug: doit
Fly-Force-Region: {{region}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "application/xml" # expect XML
header "cf-ray" exists # origin is Cloudflare
header "via" contains "Varnish" # served via Varnish
header "flyio-debug" exists # we have extra debug information
header "age" exists # cache age works
header "cache-status" contains {{region}} # region is correct
header "cache-status" contains "storage.memory" # cached in memory

GET https://{{host}}/uploads/news/175/changelog-news-175.mp3
Host: {{assets_host}}
Flyio-Debug: doit
Fly-Force-Region: {{region}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "audio/mpeg" # expect MP3
header "access-control-allow-origin" contains "*" # CORS
header "cf-ray" exists # origin is Cloudflare
header "via" contains "Varnish" # served via Varnish
header "flyio-debug" exists # we have extra debug information
header "age" exists # cache age works
header "cache-status" contains {{region}} # region is correct
header "cache-status" contains "storage.disk" # cached on disk
bytes count == 6990515 # full file size is correct

GET https://{{host}}/
Host: {{nightly_host}}
Flyio-Debug: doit
Fly-Force-Region: {{region}}
HTTP 200 # expect OK response
[Asserts]
header "content-type" contains "text/html" # expect HTML
header "cache-status" contains "fly.dev" # origin is Fly.io
header "via" contains "Varnish" # served via Varnish
header "flyio-debug" exists # we have extra debug information
header "age" exists # cache age works
header "cache-status" contains {{region}} # region is correct
header "cache-status" contains "storage.memory" # cached in memory