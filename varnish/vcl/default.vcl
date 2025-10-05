# https://varnish-cache.org/docs/7.7/reference/vcl.html#versioning
vcl 4.1;

# For duration comparisons & access to env vars
import std;

# So that we can get & set variables
import var;

# So that we can resolve backend hosts via DNS
import dynamic;

include "http.vcl";
include "www.vcl";
include "news-mp3.vcl";

# Disable default backend as we are using dynamic backends **only** so that we
# can handle new origin instances (e.g. new app version gets deployed)
backend default none;

probe backend_health {
  # The URL path to request during health checks
  # This should be a lightweight endpoint on your backend that returns a 200 status
  # when the service is healthy
  .url = "/health";

  # How frequently Varnish will poll the backend (in seconds)
  # Lower values provide faster detection of backend failures but increase load
  # Higher values reduce backend load but increase failure detection time
  .interval = 10s;

  # Maximum time to wait for a response from the backend
  # If the backend does not respond within this time, the probe is considered failed
  # Should be less than the interval to prevent probe overlap
  .timeout = 9s;

  # Number of most recent probes to consider when determining backend health
  # Varnish keeps a sliding window of the latest probe results
  # Higher values make the health determination more stable but slower to change
  .window = 6;

  # Minimum number of probes in the window that must succeed for the backend
  # to be considered healthy
  # In this case, at least 5 out of the 10 most recent probes must be successful
  # Half the window is a common value for basic fault tolerance
  .threshold = 4;

  # Initial assumed state of the backend
  # Starts with the backend considered healthy
  .initial = 4;
}

# Setup a dynamic director
sub vcl_init {
  # https://github.com/nigoroll/libvmod-dynamic/blob/0590f76b05f9b83a5a2e1d246e67a12d66e55c27/src/vmod_dynamic.vcc#L234-L255
  new app = dynamic.director(
    ttl = 10s,
    probe = backend_health,
    host_header = std.getenv("BACKEND_APP_FQDN"),
    # Increase first_byte_timeout so that mp3 uploads work
    first_byte_timeout = 300s,
    connect_timeout = 10s,
    between_bytes_timeout = 60s
  );

  new feeds = dynamic.director(
    ttl = 10s,
    probe = backend_health,
    host_header = std.getenv("BACKEND_FEEDS_FQDN"),
    first_byte_timeout = 10s,
    connect_timeout = 10s,
    between_bytes_timeout = 60s
  );

  new assets = dynamic.director(
    ttl = 10s,
    probe = backend_health,
    host_header = std.getenv("BACKEND_ASSETS_FQDN"),
    first_byte_timeout = 10s,
    connect_timeout = 10s,
    between_bytes_timeout = 60s
  );
}

# NOTE: vcl_recv is called at the beginning of a request, after the complete
# request has been received and parsed. Its purpose is to decide whether or not
# to serve the request, how to do it, and, if applicable, which backend to use.
sub vcl_recv {
  ### Figure out which is the best public IP to use
  # This needs to happen first, otherwise the health-checker IP will not be set correctly
  # Prefer fly-client-ip header
  if (req.http.fly-client-ip) {
    std.log("client_ip:" + req.http.fly-client-ip);
  # If the above is not present, take x-forwarded-for
  } else if (req.http.x-forwarded-for) {
    std.log("client_ip:" + regsub(req.http.x-forwarded-for, "^([^,]+).*", "\1"));
  # If neither are present, use the default
  } else {
    std.log("client_ip:" + client.ip);
  }

  ### Varnish health-check
  # This is the first HTTP endpoint that will get hit, before traffic arrives for any of the following HTTP endpoints.
  if (req.url == "/health") {
    return(synth(204));
  }
  ### Configure health-checks for all backends
  # APP
  if (req.url == "/app_health") {
  set req.http.x-backend = "app";
    set req.url = "/health";
    return(pass);
  }
  # FEEDS
  if (req.url == "/feeds_health") {
    set req.http.x-backend = "feeds";
    set req.url = "/health";
    return(pass);
  }
  # ASSETS
  if (req.url == "/assets_health") {
    set req.http.x-backend = "assets";
    set req.url = "/health";
    return(pass);
  }

  ### practical.ai redirects
  if (req.url == "/practicalai/feed"
      || req.url == "/practicalai") {
    return(synth(301, "Moved Permanently"));
  }

  ### Static assets requests
  #
  if (req.http.host == std.getenv("ASSETS_HOST")) {
   	# Reject non-GET/HEAD/PURGE requests
   	if (req.method !~ "GET|HEAD|PURGE") {
      return(synth(405, "Method Not Allowed"));
    }
    set req.http.x-backend = "assets";
  }

  ### Feed requests
  # Ordered by number of requests in April 2025 (most popular at the top)
  # https://ui.honeycomb.io/changelog/datasets/fastly/board-query/xCqdG5ysitw/result/da96aC9mAQf
  #
  # TODO: Upload feed.json too?
  #
  # FWIW 🤦 https://github.com/varnishcache/varnish-cache/issues/2355
  if (req.url ~ "^/podcast/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/podcast.xml";
  } else if (req.url ~ "^/gotime/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/gotime.xml";
  } else if (req.url ~ "^/master/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/master.xml";
  } else if (req.url ~ "^/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/feed.xml";
  } else if (req.url ~ "^/jsparty/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/jsparty.xml";
  } else if (req.url ~ "^/shipit/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/shipit.xml";
  } else if (req.url ~ "^/news/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/news.xml";
  } else if (req.url ~ "^/brainscience/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/brainscience.xml";
  } else if (req.url ~ "^/founderstalk/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/founderstalk.xml";
  } else if (req.url ~ "^/interviews/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/interviews.xml";
  } else if (req.url ~ "^/friends/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/friends.xml";
  } else if (req.url ~ "^/rfc/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/rfc.xml";
  } else if (req.url ~ "^/spotlight/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/spotlight.xml";
  } else if (req.url ~ "^/afk/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/afk.xml";
  } else if (req.url ~ "^/posts/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/posts.xml";
  } else if (req.url ~ "^/plusplus/xae9heiphohtupha1Ahha3aexoo0oo4W/feed/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/plusplus.xml";
  } else if (req.url ~ "^/rss/?(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = "/feed.xml";
  } else if (req.url ~ "^/feeds/.*(\?.*)?$") {
    set req.http.x-backend = "feeds";
    set req.url = regsub(req.url, "^/feeds/([^?]*)(\?.*)?$", "/\1.xml");
  }

  ### PURGE
  # https://varnish-cache.org/docs/7.7/users-guide/purging.html
  if (req.method == "PURGE") {
    # If no token token is configured allow un-authenticated PURGEs, otherwise require it.
    if (std.getenv("PURGE_TOKEN") == "" || req.http.purge-token == std.getenv("PURGE_TOKEN")) {
      return(purge);
    } else {
      return(synth(401, "Invalid PURGE token"));
    }
  }
}

sub vcl_hash {
	if (req.http.x-backend == "assets") {
	  set req.backend_hint = assets.backend(std.getenv("BACKEND_ASSETS_HOST"), std.getenv("BACKEND_ASSETS_PORT"));
		set req.http.x-backend-fqdn = std.getenv("BACKEND_ASSETS_FQDN");
	} else if (req.http.x-backend == "feeds") {
	  set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
		set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
	} else {
	  set req.backend_hint = app.backend(std.getenv("BACKEND_APP_HOST"), std.getenv("BACKEND_APP_PORT"));
	  set req.http.x-backend-fqdn = std.getenv("BACKEND_APP_FQDN");
	}
}

sub vcl_pass {
	# Bypass caching
	set req.http.x-bypass = "true";
	if (req.http.x-backend == "assets") {
	  set req.backend_hint = assets.backend(std.getenv("BACKEND_ASSETS_HOST"), std.getenv("BACKEND_ASSETS_PORT"));
		set req.http.x-backend-fqdn = std.getenv("BACKEND_ASSETS_FQDN");
	} else if (req.http.x-backend == "feeds") {
	  set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
	  set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
	} else {
	  set req.backend_hint = app.backend(std.getenv("BACKEND_APP_HOST"), std.getenv("BACKEND_APP_PORT"));
	  set req.http.x-backend-fqdn = std.getenv("BACKEND_APP_FQDN");
	}
}

sub vcl_synth {
	# Reject non-GET/HEAD/PURGE requests
	if (req.http.host == std.getenv("BACKEND_ASSETS_FQDN")
	    && resp.status == 405) {
    set resp.http.allow = "GET, HEAD, PURGE";
    return(deliver);
	}

  # practical.ai redirects
  if (req.url == "/practicalai/feed"
      && resp.status == 301) {
    set resp.http.location = "https://feeds.transistor.fm/practical-ai-machine-learning-data-science-llm";
    set resp.body = {"
<html><body>You are being <a href="https://feeds.transistor.fm/practical-ai-machine-learning-data-science-llm">redirected</a>.</body></html>
    "};
    return(deliver);
  }

  if (req.url == "/practicalai"
      && resp.status == 301) {
    set resp.http.location = "https://practicalai.fm";
    set resp.body = {"
        <html><body>You are being <a href="https://practicalai.fm">redirected</a>.</body></html>
    "};
    return(deliver);
  }

  # Which region is serving this request?
  var.set("region", std.getenv("FLY_REGION"));
  if (var.get("region") == "") {
    var.set("region", "LOCAL");
  }
  set resp.http.cache-status = "region=" + var.get("region") + "; synth";
  std.log("server_datacenter:" + var.get("region"));
}

# https://varnish-cache.org/docs/7.7/users-guide/vcl-grace.html
# https://docs.varnish-software.com/tutorials/object-lifetime/
# https://www.varnish-software.com/developers/tutorials/http-caching-basics/
# https://blog.markvincze.com/how-to-gracefully-fall-back-to-cache-on-5xx-responses-with-varnish/
sub vcl_backend_response {
  # Objects within ttl are considered fresh.
  set beresp.ttl = std.duration(std.getenv("BERESP_TTL"));

  # Objects within grace are considered stale.
  # Serve stale content while refreshing in the background.
  # 🤔 QUESTION: should we vary this based on backend health?
  set beresp.grace = std.duration(std.getenv("BERESP_GRACE"));

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
# https://varnish-cache.org/docs/7.7/reference/vcl-var.html#obj
sub vcl_deliver {
  # Add CORS * header for all assets responses
  if (req.http.x-backend == "assets") {
    set resp.http.access-control-allow-origin = "*";
  }

  # Which region is serving this request?
  var.set("region", std.getenv("FLY_REGION"));
  if (var.get("region") == "") {
    var.set("region", "LOCAL");
  }
  set resp.http.cache-status = "region=" + var.get("region");
  std.log("server_datacenter:" + var.get("region"));

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
  std.log("hits:" + obj.hits);
}

# LINKS:
# - https://github.com/magento/magento2/blob/03621bbcd75cbac4ffa8266a51aa2606980f4830/app/code/Magento/PageCache/etc/varnish6.vcl
# - https://abhishekjakhotiya.medium.com/magento-internals-cache-purging-and-cache-tags-bf7772e60797
