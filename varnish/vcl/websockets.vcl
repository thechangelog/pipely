sub vcl_recv {
  if (req.http.upgrade ~ "(?i)websocket") {
    return (pipe);
  }
}

sub vcl_pipe {
  if (req.http.upgrade) {
    set bereq.http.upgrade = req.http.upgrade;
    set bereq.http.connection = req.http.connection;
    set bereq.http.sec-websocket-key = req.http.sec-websocket-key;
    set bereq.http.sec-websocket-version = req.http.sec-websocket-version;
    if (req.http.sec-websocket-protocol) {
      set bereq.http.sec-websocket-protocol = req.http.sec-websocket-protocol;
    }
    if (req.http.sec-websocket-extensions) {
      set bereq.http.sec-websocket-extensions = req.http.sec-websocket-extensions;
    }
  }
}