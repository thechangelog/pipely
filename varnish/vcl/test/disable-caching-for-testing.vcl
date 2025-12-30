sub vcl_backend_response {
  # Disable caching for testing
  set beresp.uncacheable = true;
  return(deliver);
}