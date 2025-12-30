# So that we can access env vars
import std;

sub vcl_recv {
  # https://varnish-cache.org/docs/7.7/users-guide/purging.html
  if (req.method == "PURGE") {
    # If no token is configured allow un-authenticated PURGEs, otherwise require it.
    if (std.getenv("PURGE_TOKEN") == "" || req.http.purge-token == std.getenv("PURGE_TOKEN")) {
      return(purge);
    } else {
      return(synth(401, "Invalid PURGE token"));
    }
  }
}