GET {{proto}}://www.{{host}}/
HTTP 301 # expect moved permanently response
[Asserts]
header "Location" == "https://{{host}}/"
