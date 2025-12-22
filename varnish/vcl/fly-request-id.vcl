sub vcl_recv {
  # Normalize the request headers early
  # If fly-request-id exists, enforce it as the x-request-id immediately.
  if (req.http.fly-request-id) {
    set req.http.x-request-id = req.http.fly-request-id;
  }
}

sub vcl_deliver {
  # Ensure the response header matches the request header
  # Because we normalized in vcl_recv, req.http.x-request-id is already set
  # to the fly-id value if it was present.
  if (req.http.x-request-id) {
    set resp.http.x-request-id = req.http.x-request-id;
  }
}