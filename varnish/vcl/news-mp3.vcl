sub vcl_recv {
  # Remove X-Redirect header from client requests to prevent header injection
  unset req.http.X-Redirect;

  if (req.url ~ "^/uploads/podcast/news-2022-06-27/the-changelog-news-2022-06-27.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/1/changelog-news-1.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-07-04/the-changelog-news-2022-07-04.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/2/changelog-news-2.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-07-11/the-changelog-news-2022-07-11.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/3/changelog-news-3.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-07-18/the-changelog-news-2022-07-18.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/4/changelog-news-4.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-07-25/the-changelog-news-2022-07-25.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/5/changelog-news-5.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-08-01/the-changelog-news-2022-08-01.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/6/changelog-news-6.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-08-08/the-changelog-news-2022-08-08.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/7/changelog-news-7.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-08-15/the-changelog-news-2022-08-15.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/8/changelog-news-8.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-08-22/the-changelog-news-2022-08-22.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/9/changelog-news-9.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-08-22/the-changelog-news-2022-08-22-j2g.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/9/changelog-news-9-j2g.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-08-29/the-changelog-news-2022-08-29.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/10/changelog-news-10.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-09-05/the-changelog-news-2022-09-05.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/11/changelog-news-11.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-09-12/the-changelog-news-2022-09-12.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/12/changelog-news-12.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-09-19/the-changelog-news-2022-09-19.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/13/changelog-news-13.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-09-26/the-changelog-news-2022-09-26.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/14/changelog-news-14.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-10-03/the-changelog-news-2022-10-03.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/15/changelog-news-15.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-10-10/the-changelog-news-2022-10-10.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/16/changelog-news-16.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-10-17/the-changelog-news-2022-10-17.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/17/changelog-news-17.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-10-24/the-changelog-news-2022-10-24.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/18/changelog-news-18.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-11-07/the-changelog-news-2022-11-07.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/19/changelog-news-19.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-11-14/the-changelog-news-2022-11-14.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/20/changelog-news-20.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-11-21/the-changelog-news-2022-11-21.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/21/changelog-news-21.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-11-28/the-changelog-news-2022-11-28.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/22/changelog-news-22.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-12-05/the-changelog-news-2022-12-05.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/23/changelog-news-23.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2022-12-12/the-changelog-news-2022-12-12.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/24/changelog-news-24.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-01-02/the-changelog-news-2023-01-02.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/25/changelog-news-25.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-01-09/the-changelog-news-2023-01-09.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/26/changelog-news-26.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-01-16/the-changelog-news-2023-01-16.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/27/changelog-news-27.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-01-23/the-changelog-news-2023-01-23.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/28/changelog-news-28.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-01-30/the-changelog-news-2023-01-30.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/29/changelog-news-29.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-02-06/the-changelog-news-2023-02-06.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/30/changelog-news-30.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-02-13/the-changelog-news-2023-02-13.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/31/changelog-news-31.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-02-20/the-changelog-news-2023-02-20.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/32/changelog-news-32.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-02-20/the-changelog-news-2023-02-20-p883.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/32/changelog-news-32p883.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-02-27/the-changelog-news-2023-02-27.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/33/changelog-news-33.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-03-06/the-changelog-news-2023-03-06.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/34/changelog-news-34.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-03-06/the-changelog-news-2023-03-06-XXXL.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/34/changelog-news-34-XXXL.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-03-13/the-changelog-news-2023-03-13.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/35/changelog-news-35.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-03-20/the-changelog-news-2023-03-20.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/36/changelog-news-36.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-03-27/the-changelog-news-2023-03-27.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/37/changelog-news-37.mp3";
  } else if (req.url ~ "^/uploads/podcast/news-2023-04-03/the-changelog-news-2023-04-03.mp3($|\?)") {
    set req.http.X-Redirect = "/uploads/news/38/changelog-news-38.mp3";
  }

  if (req.http.X-Redirect) {
    return (synth(308, "Permanent Redirect"));
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
