import std;

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
}