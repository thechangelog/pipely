import std;

sub vcl_recv {
  # This header selects the FEEDS backend & cache policy below.
  # Unset it on every client request to prevent header injection.
  unset req.http.x-backend-feeds;

  if (req.url == "/feeds_health") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/health";
    return(pass);
  }

  ### Feed requests
  #
  # Normalize all feed URLs to the canonical /<feed>.xml form, the only form
  # served by the feeds backend. The query string is always dropped: feeds are
  # static files & this keeps a single cache object per feed.
  #
  # Feed allowlist based on requests in April 2025:
  # https://ui.honeycomb.io/changelog/datasets/fastly/board-query/xCqdG5ysitw/result/da96aC9mAQf
  #
  # TODO: Upload feed.json too?
  #
  # FWIW 🤦 https://github.com/varnishcache/varnish-cache/issues/2355

  # Podcast feeds, e.g. /podcast/feed → /podcast.xml
  if (req.url ~ "^/(podcast|gotime|master|jsparty|shipit|news|brainscience|founderstalk|interviews|friends|rfc|spotlight|afk|posts)/feed/?(\?.*)?$") {
    set req.url = regsub(req.url, "^/([a-z]+)/feed/?(\?.*)?$", "/\1.xml");
    set req.http.x-backend-feeds = true;
  # Site-wide feed aliases
  } else if (req.url ~ "^/(feed|rss)/?(\?.*)?$") {
    set req.url = "/feed.xml";
    set req.http.x-backend-feeds = true;
  # The ++ feed is private: only reachable via its tokenized URL, which is why
  # /plusplus.xml is deliberately NOT in the direct .xml allowlist below.
  # The URL is only normalized here; the rewrite to /plusplus.xml happens in
  # vcl_backend_fetch so that the token stays in the cache key & a request
  # without the token can never hit the cached private feed.
  } else if (req.url ~ "^/plusplus/xae9heiphohtupha1Ahha3aexoo0oo4W/feed/?(\?.*)?$") {
    set req.url = "/plusplus/xae9heiphohtupha1Ahha3aexoo0oo4W/feed";
    set req.http.x-backend-feeds = true;
  # Personal & other feeds, e.g. /feeds/<id> → /<id>.xml
  } else if (req.url ~ "^/feeds/") {
    set req.url = regsub(req.url, "^/feeds/([^?]*)(\?.*)?$", "/\1.xml");
    # The private ++ feed must never be reachable without its token
    if (req.url != "/plusplus.xml") {
      set req.http.x-backend-feeds = true;
    }
  # Direct requests for the canonical form, e.g. /feed.xml (old bookmarks & crawlers)
  } else if (req.url ~ "^/(feed|podcast|gotime|master|jsparty|shipit|news|brainscience|founderstalk|interviews|friends|rfc|spotlight|afk|posts)\.xml(\?.*)?$") {
    set req.url = regsub(req.url, "\?.*$", "");
    set req.http.x-backend-feeds = true;
  }

  # All feed requests are served by the same FEEDS backend
  if (req.http.x-backend-feeds) {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");

    # Feed access control is via tokenized URLs, never via credentials.
    # Drop them so that the builtin vcl_recv does not pass these requests
    # (they would never be served from the cache otherwise).
    unset req.http.cookie;
    unset req.http.authorization;
  }
}

sub vcl_backend_fetch {
  # The private ++ feed: the tokenized URL is the cache key (see vcl_recv);
  # only the backend request is rewritten to the canonical form
  if (bereq.url == "/plusplus/xae9heiphohtupha1Ahha3aexoo0oo4W/feed") {
    set bereq.url = "/plusplus.xml";
  }
}

# https://varnish-cache.org/docs/7.7/users-guide/vcl-grace.html
# https://docs.varnish-software.com/tutorials/object-lifetime/
# https://www.varnish-software.com/developers/tutorials/http-caching-basics/
sub vcl_backend_response {
  if (bereq.http.x-backend-feeds) {
    # Use memory for cache storage ONLY
    set beresp.storage = storage.memory;

    # Objects within ttl are considered fresh.
    set beresp.ttl = 12h;

    # Objects within grace are considered stale.
    # Serve stale content while refreshing in the background.
    set beresp.grace = 1d;

    # Keep the object in cache for some additional time
    # so that the backend does not need to retransmit the object if not modified
    set beresp.keep = 7d;
  }
}
