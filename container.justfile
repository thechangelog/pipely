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
    goreman --set-ports=false start

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
    hurl --test --color --report-html /var/opt/hurl/test-acceptance-local --variable host=http://localhost:9000 --variable delay_ms=6000 --variable delay_s=5 {{ ARGS }} test/acceptance/*.hurl test/acceptance/cdn2/*.hurl

# Show Varnish cache stats
cache:
    varnishncsa -c -f '%m %u %h %{x-cache}o %{x-cache-hits}o'

# Benchmark $url as http version $http with $reqs across $conns
bench url="http://localhost:9000/" http="1.1" reqs="1000" conns="50":
    time oha -n {{ reqs }} -c {{ conns }} {{ url }} --http-version={{ http }}

# Benchmark app via local Varnish
bench-app: (bench "http://localhost:9000/" "2" "200000")

# Benchmark app TLS proxy
bench-app-tls-proxy: (bench "http://localhost:5000/")

# Benchmark app origin
bench-app-origin: (bench "https://changelog-2024-01-12.fly.dev/")

# Benchmark feeds via local Varnish
bench-feeds: (bench "http://localhost:9000/feed" "2" "200000")

# Benchmark feeds TLS proxy
bench-feeds-tls-proxy: (bench "http://localhost:5010/feed.xml")

# Benchmark feeds origin
bench-feeds-origin: (bench "https://feeds.changelog.place/feed.xml")

# Benchmark cdn
bench-cdn: (bench "https://changelog.com/" "2" "100000")

# Benchmark cdn2
bench-cdn2: (bench "https://cdn2.changelog.com/" "2" "100000")
