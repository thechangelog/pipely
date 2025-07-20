sub vcl_recv {
  # Check if the proxy layer marked this as an http connection
  if (req.http.x-forwarded-proto == "http") {
    return (synth(301, "Moved Permanently"));
  }
}

sub vcl_synth {
  # Handle the redirect
  if (req.http.x-forwarded-proto == "http"
      && resp.status == 301) {
    set resp.http.Location = "https://" + req.http.host + req.url;
    return (deliver);
  }
}
