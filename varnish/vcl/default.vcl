# https://varnish-cache.org/docs/7.7/reference/vcl.html#versioning
vcl 4.1;

import dynamic;
import std;
import var;

# We are using a dynamic backend so that we can handle new origin instances (e.g. new app version gets deployed)
#
# We are declaring the dynamic directors here so that when testing & importing the backends
# we can define dynamic directors WITHOUT health probes
sub vcl_init {
  if (std.getenv("FLY_APP") && std.getenv("FLY_APP") != "") {
      var.global_set("app_generation", std.getenv("FLY_APP"));
  } else {
      var.global_set("app_generation", "NOW");
  }

  if (std.getenv("FLY_REGION") && std.getenv("FLY_REGION") != "") {
      var.global_set("region", std.getenv("FLY_REGION"));
  } else {
      var.global_set("region", "LOCAL");
  }

  # https://github.com/nigoroll/libvmod-dynamic/blob/branch-7.7/src/vmod_dynamic.vcc#L234-L255
  new app = dynamic.director(
    ttl = 10s,
    probe = backend_health_200,
    host_header = std.getenv("BACKEND_APP_FQDN"),
    # Increase first_byte_timeout so that mp3 uploads work
    first_byte_timeout = 300s,
    connect_timeout = 10s,
    between_bytes_timeout = 60s
  );

  new assets = dynamic.director(
    ttl = 10s,
    probe = backend_health_200,
    host_header = std.getenv("BACKEND_ASSETS_FQDN"),
    first_byte_timeout = 10s,
    connect_timeout = 10s,
    between_bytes_timeout = 60s
  );

  new feeds = dynamic.director(
    ttl = 10s,
    probe = backend_health_200,
    host_header = std.getenv("BACKEND_FEEDS_FQDN"),
    first_byte_timeout = 10s,
    connect_timeout = 10s,
    between_bytes_timeout = 60s
  );

  new nightly = dynamic.director(
    ttl = 10s,
    probe = backend_health_204,
    host_header = std.getenv("BACKEND_NIGHTLY_FQDN"),
    first_byte_timeout = 10s,
    connect_timeout = 10s,
    between_bytes_timeout = 60s
  );
}

include "app-backend.vcl";
include "assets-backend.vcl";
include "backend-health-200.vcl";
include "backend-health-204.vcl";
include "disable-caching-for-5xx.vcl";
include "disable-default-backend.vcl";
include "feeds-backend.vcl";
include "fly/app-generation.vcl";
include "fly/client-ip.vcl";
include "fly/request-id.vcl";
include "http.vcl";
include "news-mp3.vcl";
include "nightly-backend.vcl";
include "practicalai.vcl";
include "purge.vcl";
include "fly/region.vcl";
include "varnish-health.vcl";
include "websockets.vcl";
include "www.vcl";

# The following MUST run AFTER all the includes which is why it's added inline
#
sub vcl_backend_response {
  # If this is set (only recommended for dev / testing), it WILL overwrite the backend-specific settings
  if (std.getenv("BERESP_TTL")) {
    # Objects within ttl are considered fresh.
    set beresp.ttl = std.duration(std.getenv("BERESP_TTL"));
  }

  # If this is set (only recommended for dev / testing), it WILL overwrite the backend-specific settings
  if (std.getenv("BERESP_GRACE")) {
    # Objects within grace are considered stale.
    # Serve stale content while refreshing in the background.
    set beresp.grace = std.duration(std.getenv("BERESP_GRACE"));
  }

  # If this is set (only recommended for dev / testing), it WILL overwrite the backend-specific settings
  if (std.getenv("BERESP_KEEP")) {
    # Keep the object in cache for some additional time
    # so that the backend does not need to retransmit the object if not modified
    set beresp.keep = std.duration(std.getenv("BERESP_KEEP"));
  }
}

sub vcl_pass {
	# Bypass caching
	set req.http.x-bypass = "true";
}

sub vcl_deliver {
  # Which origin is serving this request?
  set resp.http.cache-status = resp.http.cache-status + "; origin=" + req.backend_hint + "," + req.http.x-backend-fqdn;
  std.log("backend:" + req.http.x-backend-fqdn);

  if (req.http.x-bypass == "true") {
    set resp.http.cache-status = resp.http.cache-status + "; bypass";
    return(deliver);
  }

  # What is the remaining TTL for this object?
  set resp.http.cache-status = resp.http.cache-status + "; ttl=" + obj.ttl;
  std.log("ttl:" + obj.ttl);

  # What is the max object staleness permitted?
  set resp.http.cache-status = resp.http.cache-status + "; grace=" + obj.grace;
  std.log("grace:" + obj.grace);

  # How long should we keep an object in cache for?
  set resp.http.cache-status = resp.http.cache-status + "; keep=" + obj.keep;
  std.log("keep:" + obj.keep);

  # Did the response come from Varnish or from the backend? Which type of cache storage?
  if (obj.hits > 0) {
    set resp.http.cache-status = resp.http.cache-status + "; storage=" + obj.storage + "; hit";
    std.log("storage:" + obj.storage);
  } else {
    set resp.http.cache-status = resp.http.cache-status + "; storage=none; miss";
    std.log("storage:none");
  }

  # Is this object stale?
  if (obj.hits > 0 && obj.ttl < std.duration(integer=0)) {
    set resp.http.cache-status = resp.http.cache-status + "; stale";
  }

  # How many times has this response been served from Varnish?
  set resp.http.cache-status = resp.http.cache-status + "; hits=" + obj.hits;
  std.log("hits:" + obj.hits);
}
