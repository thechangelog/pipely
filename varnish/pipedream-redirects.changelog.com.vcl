sub vcl_recv {

    # redirects
    # /uploads/podcast/news-2022-06-27/the-changelog-news-2022-06-27.mp3 /uploads/news/1/changelog-news-1.mp3
    # /uploads/podcast/news-2022-07-04/the-changelog-news-2022-07-04.mp3 /uploads/news/2/changelog-news-2.mp3
    # /uploads/podcast/news-2022-07-11/the-changelog-news-2022-07-11.mp3 /uploads/news/3/changelog-news-3.mp3

    # testing
    # httpstat "http://localhost:9000/uploads/podcast/news-2022-06-27/the-changelog-news-2022-06-27.mp3"
    # httpstat "http://localhost:9000/uploads/podcast/news-2022-06-27/the-changelog-news-2022-06-27.mp3?this=is&a=query&string"

    # comparison
    # httpstat "http://www.changelog.com/uploads/podcast/news-2022-06-27/the-changelog-news-2022-06-27.mp3"
    # httpstat "http://www.changelog.com/uploads/podcast/news-2022-06-27/the-changelog-news-2022-06-27.mp3?this=is&a=query&string"

    if (req.url ~ "^/uploads/podcast/news-2022-06-27/the-changelog-news-2022-06-27.mp3($|\?)") {
        set req.http.X-Redirect = "/uploads/news/1/changelog-news-1.mp3";
    } else if (req.url ~ "^/uploads/podcast/news-2022-07-04/the-changelog-news-2022-07-04.mp3($|\?)") {
        set req.http.X-Redirect = "/uploads/news/2/changelog-news-2.mp3";
    } else if (req.url ~ "^/uploads/podcast/news-2022-07-11/the-changelog-news-2022-07-11.mp3($|\?)") {
        set req.http.X-Redirect = "/uploads/news/3/changelog-news-3.mp3";
    }

    if (req.http.X-Redirect) {
        return (synth(308, ""));
    }
}

sub vcl_synth {
    if (resp.status == 308 && req.http.X-Redirect) {
        set resp.http.Location = "https://" + req.http.Host + req.http.X-Redirect;

        # If a query string exists, append it to the new path
        if (req.url ~ "\?.+") {
            set resp.http.Location += regsub(req.url, "^[^?]*", "");
        }

        return (deliver);
    }
}
