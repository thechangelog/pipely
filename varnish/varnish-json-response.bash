#!/usr/bin/env bash
set -eu

# https://varnish-cache.org/docs/trunk/reference/varnishncsa.html
# https://varnish-cache.org/docs/trunk/reference/vsl.html
#
# NOTE: When GEOIP_ENRICHED=true env var, GeoIP enrichment is handled by Vector.dev using the `client_ip` value below:

VARNISH_LOG_FORMAT='{"time": "%{%Y-%m-%dT%H:%M:%SZ}t", "request_referer": "%{referer}i", "request_user_agent": "%{user-agent}i", "request_accept_content": "%{accept}i", "req_header_size": "%{VSL:ReqAcct[1]}x", "req_body_size": "%{VSL:ReqAcct[2]}x", "req_total_size": "%{VSL:ReqAcct[3]}x", "client_ip": "%{VCL_Log:client_ip}x", "protocol": "%H", "request": "%m", "host": "%{host}i", "url": "%U", "content_type": "%{content-type}o", "status": "%s", "cache_status": "%{Varnish:handling}x", "hits": "%{VCL_Log:hits}x", "ttl": "%{VCL_Log:ttl}x", "grace": "%{VCL_Log:grace}x", "server_datacenter": "%{VCL_Log:server_datacenter}x", "origin": "%{VCL_Log:backend}x", "time_first_byte_s": "%{Varnish:time_firstbyte}x", "time_elapsed": "%D", "resp_header_size": "%{VSL:ReqAcct[4]}x", "resp_body_size": "%{VSL:ReqAcct[5]}x", "resp_total_size": "%{VSL:ReqAcct[6]}x"}'

exec varnishncsa -jF "$VARNISH_LOG_FORMAT"
