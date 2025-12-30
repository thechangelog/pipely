import std;
import var;

sub vcl_synth {
  var.set("region", std.getenv("FLY_REGION"));
  if (var.get("region") == "") {
    var.set("region", "LOCAL");
  }
  set resp.http.cache-status = "region=" + var.get("region") + "; synth";
  std.log("server_datacenter:" + var.get("region"));
}

sub vcl_deliver {
  var.set("region", std.getenv("FLY_REGION"));
  if (var.get("region") == "") {
    var.set("region", "LOCAL");
  }
  set resp.http.cache-status = "region=" + var.get("region");
  std.log("server_datacenter:" + var.get("region"));
}