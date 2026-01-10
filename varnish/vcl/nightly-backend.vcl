import std;

sub vcl_recv {
  if (req.http.host == std.getenv("NIGHTLY_HOST")
      || req.url == "/nightly_health") {
    set req.backend_hint = nightly.backend(
      std.getenv("BACKEND_NIGHTLY_HOST"),
      std.getenv("BACKEND_NIGHTLY_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_NIGHTLY_FQDN");
    set req.http.x-backend-nightly = true;
    set req.http.x-forwarded-host = std.getenv("NIGHTLY_HOST");

    # Reject non-GET/HEAD/PURGE requests
    if (req.method !~ "GET|HEAD|PURGE") {
      return(synth(405, "Method Not Allowed"));
    }

    if (req.url == "/nightly_health") {
      set req.url = "/health";
      return(pass);
    }
  }
}

sub vcl_synth {
	# Reject non-GET/HEAD/PURGE requests
	if (req.http.x-backend-nightly
	    && resp.status == 405) {
    set resp.http.allow = "GET, HEAD, PURGE";
    return(deliver);
	}
}

# https://gist.github.com/leotsem/1246511/824cb9027a0a65d717c83e678850021dad84688d#file-default-vcl-pl
# https://varnish-cache.org/docs/7.7/reference/vcl-var.html#obj
sub vcl_deliver {
  # Add CORS * header for all nightly responses
  if (req.http.x-backend-nightly) {
    set resp.http.access-control-allow-origin = "*";
  }
}

# https://varnish-cache.org/docs/7.7/users-guide/vcl-grace.html
# https://docs.varnish-software.com/tutorials/object-lifetime/
# https://www.varnish-software.com/developers/tutorials/http-caching-basics/
sub vcl_backend_response {
  if (bereq.http.x-backend-nightly) {
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