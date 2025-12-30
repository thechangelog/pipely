sub vcl_recv {
  if (req.url == "/health") {
    return(synth(204));
  }
}