GET {{host}}/podcast/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/gotime/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/master/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/jsparty/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/shipit/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/news/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/brainscience/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/founderstalk/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/interviews/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/feed/
[Options]
skip: true
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/rfc/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/spotlight/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/afk/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/posts/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML

GET {{host}}/plusplus/xae9heiphohtupha1Ahha3aexoo0oo4W/feed
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML
