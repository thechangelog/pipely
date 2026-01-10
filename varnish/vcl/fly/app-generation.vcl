import std;
import var;

sub vcl_synth {
  std.log("app_generation:" + var.global_get("app_generation"));
}

sub vcl_deliver {
  std.log("app_generation:" + var.global_get("app_generation"));
}