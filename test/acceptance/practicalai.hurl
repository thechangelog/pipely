GET {{proto}}://{{host}}/practicalai
HTTP 301 # expect moved permanently response
[Asserts]
header "location" == "https://practicalai.fm"
body contains "<html><body>You are being <a href=\"https://practicalai.fm\">redirected</a>.</body></html>"


GET {{proto}}://{{host}}/practicalai/feed
HTTP 301 # expect moved permanently response
[Asserts]
header "location" == "https://feeds.transistor.fm/practical-ai-machine-learning-data-science-llm"
body contains "<html><body>You are being <a href=\"https://feeds.transistor.fm/practical-ai-machine-learning-data-science-llm\">redirected</a>.</body></html>"
