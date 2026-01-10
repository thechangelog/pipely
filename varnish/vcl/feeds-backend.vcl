import std;

sub vcl_recv {
  if (req.url == "/feeds_health") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/health";
    return(pass);
  }

  ### Feed requests
  # Ordered by number of requests in April 2025 (most popular at the top)
  # https://ui.honeycomb.io/changelog/datasets/fastly/board-query/xCqdG5ysitw/result/da96aC9mAQf
  #
  # TODO: Upload feed.json too?
  #
  # FWIW 🤦 https://github.com/varnishcache/varnish-cache/issues/2355
  if (req.url ~ "^/podcast/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/podcast.xml";
  } else if (req.url ~ "^/gotime/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/gotime.xml";
  } else if (req.url ~ "^/master/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/master.xml";
  } else if (req.url ~ "^/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/feed.xml";
  } else if (req.url ~ "^/jsparty/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/jsparty.xml";
  } else if (req.url ~ "^/shipit/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/shipit.xml";
  } else if (req.url ~ "^/news/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/news.xml";
  } else if (req.url ~ "^/brainscience/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/brainscience.xml";
  } else if (req.url ~ "^/founderstalk/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/founderstalk.xml";
  } else if (req.url ~ "^/interviews/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/interviews.xml";
  } else if (req.url ~ "^/friends/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/friends.xml";
  } else if (req.url ~ "^/rfc/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/rfc.xml";
  } else if (req.url ~ "^/spotlight/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/spotlight.xml";
  } else if (req.url ~ "^/afk/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/afk.xml";
  } else if (req.url ~ "^/posts/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/posts.xml";
  } else if (req.url ~ "^/plusplus/xae9heiphohtupha1Ahha3aexoo0oo4W/feed/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/plusplus.xml";
  } else if (req.url ~ "^/rss/?(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = "/feed.xml";
  } else if (req.url ~ "^/feeds/.*(\?.*)?$") {
    set req.backend_hint = feeds.backend(std.getenv("BACKEND_FEEDS_HOST"), std.getenv("BACKEND_FEEDS_PORT"));
    set req.http.x-backend-fqdn = std.getenv("BACKEND_FEEDS_FQDN");
    set req.http.x-backend-feeds = true;
    set req.http.x-forwarded-host = std.getenv("FEEDS_HOST");
    set req.url = regsub(req.url, "^/feeds/([^?]*)(\?.*)?$", "/\1.xml");
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