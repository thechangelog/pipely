GET {{proto}}://{{host}}/static/images/podcasts/podcast-original-f16d0363067166f241d080ee2e2d4a28.png
Host: {{assets_host}}
HTTP 200 # expect OK response
Content-Type: image/png # expect PNG
Access-Control-Allow-Origin: * # CORS
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works

HEAD {{proto}}://{{host}}/static/images/podcasts/podcast-original-f16d0363067166f241d080ee2e2d4a28.png
Host: {{assets_host}}
HTTP 200 # expect OK response
Content-Type: image/png # expect PNG
Access-Control-Allow-Origin: * # CORS
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works

POST {{proto}}://{{host}}/static/images/podcasts/podcast-original-f16d0363067166f241d080ee2e2d4a28.png
Host: {{assets_host}}
HTTP 405 # expect method not allowed

GET {{proto}}://{{host}}/static/css/email-5690e09e20c0b25fefebbc5049362b39.css
Host: {{assets_host}}
HTTP 200 # expect OK response
Content-Type: text/css # expect CSS
Access-Control-Allow-Origin: * # CORS
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works

GET {{proto}}://{{host}}/uploads/news/140/changelog-news-140.mp3
Host: {{assets_host}}
HTTP 200 # expect OK response
Content-Type: audio/mpeg # expect MP3
Access-Control-Allow-Origin: * # CORS
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
bytes count == 8575592 # full file size is correct

# Request first mp3 chunk
GET {{proto}}://{{host}}/uploads/news/140/changelog-news-140.mp3
Range: bytes=0-1023
Host: {{assets_host}}
HTTP 206 # expect partial content response
Content-Type: audio/mpeg # expect MP3
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
bytes count == 1024 # first chunk size is correct

# Request middle mp3 chunk
GET {{proto}}://{{host}}/uploads/news/140/changelog-news-140.mp3
Range: bytes=1024-2047
Host: {{assets_host}}
HTTP 206 # expect partial content response
Content-Type: audio/mpeg
Content-Range: bytes 1024-2047/8575592
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
bytes count == 1024 # middle chunk size is correct

# Request end mp3 chunk
GET {{proto}}://{{host}}/uploads/news/140/changelog-news-140.mp3
Range: bytes=-1024
Host: {{assets_host}}
HTTP 206 # expect partial content response
Content-Type: audio/mpeg
Content-Range: bytes 8574568-8575591/8575592
[Asserts]
header "cf-ray" exists # served by Cloudflare
header "via" matches /[vV]arnish/ # served via Varnish
header "age" exists # cache age works
bytes count == 1024 # last chunk size is correct
