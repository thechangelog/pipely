# vim: set tabstop=4 shiftwidth=4 expandtab:

set shell := ["bash", "-uc"]

[private]
default:
    @just --list

[private]
fmt:
    just --fmt --check --unstable
    just --version

# Start all processes
up:
    overmind start --timeout=30 --no-port --auto-restart=all

# Check $url
check url="http://localhost:9000":
    httpstat {{ url }}

# List Varnish backends
backends:
    varnishadm backend.list

# Tail Varnish backend_health
health:
    varnishlog -g raw -i backend_health

# Varnish top
top:
    varnishtop

# Varnish stat
stat:
    varnishstat

# Run VCL tests
test-vtc *ARGS:
    varnishtest {{ ARGS }} test/vtc/*

# Run acceptance tests
test-acceptance-local *ARGS:
    hurl --test --color --continue-on-error --report-html /var/opt/hurl/test-acceptance-local \
     --variable host=http://localhost:9000 \
     --variable assets_host=cdn2.changelog.com \
     --variable delay_ms=6000 \
     --variable delay_s=5 \
     --variable purge_token=${PURGE_TOKEN:-""} \
     {{ ARGS }} \
     test/acceptance/*.hurl test/acceptance/pipedream/*.hurl

# Show Varnish cache stats
cache:
    varnishncsa -c -f '%m %u %h %{x-cache}o %{x-cache-hits}o'

[private]
bench url="http://localhost:9000/" http="2" reqs="1000" conns="50":
    time oha -n {{ reqs }} -c {{ conns }} {{ url }} --http-version={{ http }}

# Benchmark app origin
bench-app-1-origin: (bench "https://changelog-2025-05-05.fly.dev/")

# Benchmark app Fastly
bench-app-2-fastly: (bench "https://changelog.com/" "2" "10000")

# Benchmark app Bunny
bench-app-3-bunny: (bench "https://bunny.changelog.com/")

# Benchmark app Pipedream
bench-app-4-pipedream: (bench "https://pipedream.changelog.com/" "2" "10000")

# Benchmark app via local Varnish
bench-app-5-local: (bench "http://localhost:9000/" "2" "10000")

# Benchmark app TLS proxy
bench-app-6-tls-proxy: (bench "http://localhost:5000/" "1.1")

# Benchmark feed origin
bench-feed-1-origin: (bench "https://feeds.changelog.place/podcast.xml")

# Benchmark feed Fastly
bench-feed-2-fastly: (bench "https://changelog.com/podcast/feed")

# Benchmark feed Bunny CDN
bench-feed-3-bunny: (bench "https://bunny.changelog.com/podcast/feed")

# Benchmark feed Pipedream
bench-feed-4-pipedream: (bench "https://pipedream.changelog.com/podcast/feed")

# Benchmark feed via local Varnish
bench-feed-5-local: (bench "http://localhost:9000/podcast/feed" "2" "10000" "50")

# Benchmark feed TLS proxy
bench-feed-6-tls-proxy: (bench "http://localhost:5010/podcast.xml" "1.1")
