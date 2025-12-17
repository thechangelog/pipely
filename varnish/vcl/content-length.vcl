import std;

sub vcl_backend_response {
  # Capture the Content-Length from the origin before Varnish touches it.
  # We store it in a temporary header (persists into the cache object).
  if (beresp.http.Content-Length) {
    set beresp.http.x-original-length = beresp.http.Content-Length;
  }
}

sub vcl_deliver {
  # Determine the "Truth" about size:
  # - The actual header sent to the client (if it exists).
  # - The original header we saved from the backend (if A is missing/chunked).

  if (resp.http.content-length) {
      std.log("content_length: " + resp.http.content-length);
  }
  elsif (resp.http.x-original-length) {
      std.log("content_length: " + resp.http.x-original-length);
  }
  else {
      # Fallback if absolutely no length is known (rare)
      std.log("content_length: 0");
  }

  # Remove the temp header so the client doesn't see it
  unset resp.http.x-original-length;
}