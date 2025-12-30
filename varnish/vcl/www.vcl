sub vcl_recv {
  # Check if the host starts with www.
  if (req.http.host ~ "^www\.") {
    # Remove www. from the host
    set req.http.host = regsub(req.http.host, "^www\.", "");
    set req.http.www = "true";

    # Return a 301 redirect to the non-www version
    return (synth(301, "Moved Permanently"));
  }

  if (req.http.X-Redirect) {
    return (synth(308, "Permanent Redirect"));
  }
}

sub vcl_synth {
  # Handle the redirect
  if (req.http.www == "true"
      && resp.status == 301) {
    set resp.http.location = "https://" + req.http.host + req.url;
    return (deliver);
  }
}
