GET {{proto}}://{{host}}/rss
HTTP 302 # expect Found response
[Asserts]
header "via" matches /[vV]arnish/ # served via Varnish
header "location" contains "{{proto}}://{{host}}/feed" # redirects to /feed
