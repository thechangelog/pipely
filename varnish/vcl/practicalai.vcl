sub vcl_recv {
  if (req.url == "/practicalai/feed"
      || req.url == "/practicalai") {
    return(synth(301, "Moved Permanently"));
  }
}

sub vcl_synth {
  if (req.url == "/practicalai/feed"
      && resp.status == 301) {
    set resp.http.location = "https://feeds.transistor.fm/practical-ai-machine-learning-data-science-llm";
    set resp.body = {"
  <html><body>You are being <a href="https://feeds.transistor.fm/practical-ai-machine-learning-data-science-llm">redirected</a>.</body></html>
    "};
    return(deliver);
  }

  if (req.url == "/practicalai"
      && resp.status == 301) {
    set resp.http.location = "https://practicalai.fm";
    set resp.body = {"
        <html><body>You are being <a href="https://practicalai.fm">redirected</a>.</body></html>
    "};
    return(deliver);
  }
}