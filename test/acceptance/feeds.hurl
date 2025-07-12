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
