import std;
import var;

sub vcl_synth {
  set resp.http.cache-status = "region=" + var.global_get("region") + "; synth";
  std.log("server_datacenter:" + var.global_get("region"));
}

sub vcl_deliver {
  set resp.http.cache-status = "region=" + var.global_get("region");
  std.log("server_datacenter:" + var.global_get("region"));
}