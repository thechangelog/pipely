# https://blog.markvincze.com/how-to-gracefully-fall-back-to-cache-on-5xx-responses-with-varnish/
sub vcl_backend_response {
  if (beresp.status >= 500) {
    # Don't cache a 5xx response
    set beresp.uncacheable = true;

    # If is_bgfetch is true, it means that we've found and returned the cached
    # object to the client, and triggered an asynchronous background update. In
    # that case, since backend returned a 5xx, we have to abandon, otherwise
    # the previously cached object would be erased from the cache (even if we
    # set uncacheable to true).
    if (bereq.is_bgfetch) {
      return (abandon);
    }
  }
}