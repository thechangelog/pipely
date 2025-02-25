# https://varnish-cache.org/docs/7.4/reference/vcl.html#versioning
vcl 4.1;

# Import std for duration comparisons & access to env vars
import std;

# Import var so that we can get & set variables
import var;

# Import vmod_dynamic so that we can resolve backend hosts via DNS
import dynamic;

# Disable default backend, we are using dynamic backends **only** so that we
# can handle new origin instances appearing (e.g. app deploys)
backend default none;

probe backend_healthz {
  .url = "/health";
  .interval = 5s;
  .timeout = 2s;
  .window = 10;
  .threshold = 5;
}

# Setup a dynamic director
sub vcl_init {
  # https://github.com/nigoroll/libvmod-dynamic/blob/3697d6f195fe077fe213918b7b67f5da4efdede2/src/tbl/list_prop.h
  new origin = dynamic.director(
    ttl = 10s,
    probe = backend_healthz,
    host_header = std.getenv("BACKEND_FQDN"),
    first_byte_timeout = 5s,
    connect_timeout = 5s,
    between_bytes_timeout = 30s
  );
}

# NOTE: vcl_recv is called at the beginning of a request, after the complete
# request has been received and parsed. Its purpose is to decide whether or not
# to serve the request, how to do it, and, if applicable, which backend to use.
sub vcl_recv {
  # https://varnish-cache.org/docs/7.4/users-guide/purging.html
  if (req.method == "PURGE") {
    return (purge);
  }

  # Implement a Varnish health-check
  if (req.method == "GET" && req.url == "/varnish_health") {
    return(synth(204));
  }

  # Make it clear what component we are health-checking
  if (req.method == "GET" && req.url == "/backend_health") {
    set req.url = "/health";
  }

  set req.backend_hint = origin.backend(std.getenv("BACKEND_HOST"), std.getenv("BACKEND_PORT"));
}

# https://varnish-cache.org/docs/7.4/users-guide/vcl-grace.html
# https://docs.varnish-software.com/tutorials/object-lifetime/
# https://www.varnish-software.com/developers/tutorials/http-caching-basics/
# https://blog.markvincze.com/how-to-gracefully-fall-back-to-cache-on-5xx-responses-with-varnish/
sub vcl_backend_response {
  # Objects within ttl are considered fresh.
  set beresp.ttl = 60s;

  # Objects within grace are considered stale.
  # Serve stale content while refreshing in the background.
  # 🤔 QUESTION: should we vary this based on backend health?
  set beresp.grace = 24h;

  if (beresp.status >= 500) {
    # Don't cache a 5xx response
    set beresp.uncacheable = true;

    # If is_bgfetch is true, it means that we've found and returned the cached
    # object to the client, and triggered an asynchoronus background update. In
    # that case, since backend returned a 5xx, we have to abandon, otherwise
    # the previously cached object would be erased from the cache (even if we
    # set uncacheable to true).
    if (bereq.is_bgfetch) {
      return (abandon);
    }
  }

  # 🤔 QUESTION: Should we configure beresp.keep?
}


# https://gist.github.com/leotsem/1246511/824cb9027a0a65d717c83e678850021dad84688d#file-default-vcl-pl
# https://varnish-cache.org/docs/7.4/reference/vcl-var.html#obj
sub vcl_deliver {
  set resp.http.cache-status = "Edge";

  # What is the remaining TTL for this object?
  set resp.http.cache-status = resp.http.cache-status + "; ttl=" + obj.ttl;
  # What is the max object staleness permitted?
  set resp.http.cache-status = resp.http.cache-status + "; grace=" + obj.grace;

  # Did the response come from Varnish or from the backend?
  if (obj.hits > 0) {
    set resp.http.cache-status = resp.http.cache-status + "; hit";
  } else {
    set resp.http.cache-status = resp.http.cache-status + "; miss";
  }

  # Is this object stale?
  if (obj.hits > 0 && obj.ttl < std.duration(integer=0)) {
    set resp.http.cache-status = resp.http.cache-status + "; stale";
  }

  # How many times has this response been served from Varnish?
  set resp.http.cache-status = resp.http.cache-status + "; hits=" + obj.hits;

  var.set("region", std.getenv("FLY_REGION"));
  if (var.get("region") == "") {
     var.set("region", "LOCAL");
  }

  # Which region is serving this request?
  set resp.http.cache-status = resp.http.cache-status + "; region=" + var.get("region");
}

# TODOS:
# - ✅ Run in debug mode (locally)
# - ✅ Connect directly to app - not Fly.io Proxy 🤦
# - ✅ Serve stale content + background refresh
#   - QUESTION: Should the app control this via Surrogate-Control? Should we remove this header?
#   - EXPLORE: varnishstat
#   - EXPLORE: varnishtop
#   - EXPLORE: varnishncsa -c -f '%m %u %h %{x-cache}o %{x-cache-hits}o'
# - ✅ Serve stale content on backend error
#   - https://varnish-cache.org/docs/7.4/users-guide/vcl-grace.html#misbehaving-servers
# - ✅ Expose FLY_REGION=sjc env var as a custom header
#   - https://github.com/varnish/docker-varnish/blob/45c6204864d46dbd9e18485c91f915f89f822859/old/debian/default.vcl#L35
# - ✅ If the backend gets restarted (e.g. new deploy), backend remains sick in Varnish
#   - https://info.varnish-software.com/blog/two-minute-tech-tuesdays-backend-health
#   - EXPLORE: varnishlog -g raw -i backend_health
#   - EXPLORE: varnishadm backend.list
# - Add Feeds backend: /feed -> https://feeds.changelog.place/feed.xml
# - Send logs to Honeycomb.io
# - Store cache on disk? A pre-requisite for static backend 
#   - https://varnish-cache.org/docs/trunk/users-guide/storage-backends.html#file
#
# FOLLOW-UPs:
# - Run varnishncsa as a separate process (will need a supervisor + log drain)
#   - https://info.varnish-software.com/blog/varnish-and-json-logging
# - How to cache purge across all varnish instances?
# - Implement If-Modified-Since? keep
#
# LINKS:
# - https://github.com/magento/magento2/blob/03621bbcd75cbac4ffa8266a51aa2606980f4830/app/code/Magento/PageCache/etc/varnish6.vcl
# - https://abhishekjakhotiya.medium.com/magento-internals-cache-purging-and-cache-tags-bf7772e60797
