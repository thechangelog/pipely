GET {{host}}/not-found
HTTP 404 # expect not found response
[Asserts]
status == 404

GET {{host}}/uploads/podcast/news-2022-06-27/the-changelog-news-2022-06-27.mp3
HTTP 308 # expect permanent redirect response
[Asserts]
header "Content-Length" == "0"
header "Location" contains "/uploads/news/1/changelog-news-1.mp3"

GET {{host}}/uploads/podcast/news-2022-06-27/the-changelog-news-2022-06-27.mp3?this=is&a=query&string
HTTP 308 # expect permanent redirect response
[Asserts]
header "Content-Length" == "0"
header "Location" contains "/uploads/news/1/changelog-news-1.mp3?this=is&a=query&string"

GET {{host}}/uploads/podcast/news-2022-07-04/the-changelog-news-2022-07-04.mp3
HTTP 308 # expect permanent redirect response
[Asserts]
header "Content-Length" == "0"
header "Location" contains "/uploads/news/2/changelog-news-2.mp3"

GET {{host}}/uploads/podcast/news-2022-07-11/the-changelog-news-2022-07-11.mp3
HTTP 308 # expect permanent redirect response
[Asserts]
header "Content-Length" == "0"
header "Location" contains "/uploads/news/3/changelog-news-3.mp3"
