GET {{host}}/rss
HTTP 200 # expect OK response
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
header "content-type" contains "application/xml" # content type is XML
