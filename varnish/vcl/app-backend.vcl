import std;

sub vcl_recv {
  # default to APP backend
  set req.backend_hint = app.backend(std.getenv("BACKEND_APP_HOST"), std.getenv("BACKEND_APP_PORT"));
  set req.http.x-backend-fqdn = std.getenv("BACKEND_APP_FQDN");
  set req.http.x-backend-app = true;
  set req.http.x-forwarded-host = std.getenv("APP_HOST");

  if (req.url == "/app_health") {
    set req.url = "/health";
    return(pass);
  }
}

# https://varnish-cache.org/docs/7.7/users-guide/vcl-grace.html
# https://docs.varnish-software.com/tutorials/object-lifetime/
# https://www.varnish-software.com/developers/tutorials/http-caching-basics/
sub vcl_backend_response {
  if (bereq.http.x-backend-app) {
    # Use memory for cache storage ONLY
    set beresp.storage = storage.memory;

    # Objects within ttl are considered fresh.
    set beresp.ttl = 1m;

    # Objects within grace are considered stale.
    # Serve stale content while refreshing in the background.
    set beresp.grace = 1d;

    # Keep the object in cache for some additional time
    # so that the backend does not need to retransmit the object if not modified
    set beresp.keep = 7d;
  }
}