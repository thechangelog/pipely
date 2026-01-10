#!/usr/bin/env bash
set -eu

# https://varnish-cache.org/docs/trunk/reference/varnishncsa.html
# https://varnish-cache.org/docs/trunk/reference/vsl.html
#
# NOTE: When GEOIP_ENRICHED=true env var, GeoIP enrichment is handled by Vector.dev using the `client_ip` value below:

VARNISH_LOG_FORMAT='{"app_generation": "%{VCL_Log:app_generation}x", "cache_status": "%{Varnish:handling}x", "client_ip": "%{VCL_Log:client_ip}x", "content_type": "%{content-type}o", "grace": "%{VCL_Log:grace}x", "hits": "%{VCL_Log:hits}x", "host": "%{host}i", "keep": "%{VCL_Log:keep}x", "origin": "%{VCL_Log:backend}x", "protocol": "%H", "req_body_size": "%{VSL:ReqAcct[2]}x", "req_header_size": "%{VSL:ReqAcct[1]}x", "req_total_size": "%{VSL:ReqAcct[3]}x", "request": "%m", "request_accept_content": "%{accept}i", "request_id":"%{x-request-id}o", "request_referer": "%{referer}i", "request_user_agent": "%{user-agent}i", "resp_body_size": "%{VSL:ReqAcct[5]}x", "resp_header_size": "%{VSL:ReqAcct[4]}x", "resp_total_size": "%{VSL:ReqAcct[6]}x", "server_datacenter": "%{VCL_Log:server_datacenter}x", "status": "%s", "storage": "%{VCL_Log:storage}x", "time": "%{%Y-%m-%dT%H:%M:%SZ}t", "time_elapsed": "%D", "time_first_byte_s": "%{Varnish:time_firstbyte}x", "ttl": "%{VCL_Log:ttl}x", "url": "%U"}'

exec varnishncsa -jF "$VARNISH_LOG_FORMAT"
