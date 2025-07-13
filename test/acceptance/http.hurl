GET http://{{host}}/
# we only add the X-Forwarded-Proto header to test local behaviour.
# Fastly ignores it.
# Fly.io overwrites this at a platform level.
X-Forwarded-Proto: http
HTTP 301 # expect moved permanently response
[Asserts]
header "Location" == "https://{{host}}/"

# Test the assets_host
GET http://{{host}}/friends/73-pipely-tech.jpg?hurl=true&http
Host: {{assets_host}}
# we only add the X-Forwarded-Proto header to test local behaviour.
# Fastly ignores it.
# Fly.io overwrites this at a platform level.
X-Forwarded-Proto: http
HTTP 301 # expect moved permanently response
[Asserts]
header "Location" contains "https://{{assets_host}}/friends/73-pipely-tech.jpg?hurl=true&http"
