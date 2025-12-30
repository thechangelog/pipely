import dynamic;
import std;

sub vcl_recv {
  if (req.http.host == std.getenv("ASSETS_HOST")
      || req.url == "/assets_health") {
    set req.backend_hint = assets.backend(
      std.getenv("BACKEND_ASSETS_HOST"),
      std.getenv("BACKEND_ASSETS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_ASSETS_FQDN");
    set req.http.x-backend-assets = true;

    # Reject non-GET/HEAD/OPTIONS/PURGE requests
    if (req.method !~ "GET|HEAD|OPTIONS|PURGE") {
      return(synth(405, "Method Not Allowed"));
    }

    if (req.url == "/assets_health") {
      set req.url = "/health";
      return(pass);
    }
  }
}

sub vcl_synth {
	# Reject non-GET/HEAD/OPTIONS/PURGE requests
	if (req.http.x-backend-assets
	    && resp.status == 405) {
    set resp.http.allow = "GET, HEAD, OPTIONS, PURGE";
    return(deliver);
	}
}

# https://gist.github.com/leotsem/1246511/824cb9027a0a65d717c83e678850021dad84688d#file-default-vcl-pl
# https://varnish-cache.org/docs/7.7/reference/vcl-var.html#obj
sub vcl_deliver {
  # Add CORS * header for all assets responses
  if (req.http.x-backend-assets) {
    set resp.http.access-control-allow-origin = "*";
  }
}

# https://varnish-cache.org/docs/7.7/users-guide/vcl-grace.html
# https://docs.varnish-software.com/tutorials/object-lifetime/
# https://www.varnish-software.com/developers/tutorials/http-caching-basics/
sub vcl_backend_response {
  if (bereq.http.x-backend-assets) {
    # If the URL contains .mp3, cache it to disk, otherwise cache it to memory
    if (bereq.url ~ "\.mp3") {
      set beresp.storage = storage.disk;
      # Deliver bytes to the client as soon as they arrive from the backend
      set beresp.do_stream = true;
      # Prevent Varnish from caching partial responses incorrectly
      set beresp.do_esi = false;
    } else {
      set beresp.storage = storage.memory;
    }

    # Objects within ttl are considered fresh.
    set beresp.ttl = 1d;

    # Objects within grace are considered stale.
    # Stale content is served while refreshing in the background.
    set beresp.grace = 2d;

    # Keep the object in cache for some additional time.
    # So that the backend does not need to retransmit the object if-not-modified
    set beresp.keep = 7d;
  }
}