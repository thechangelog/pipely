# Local Development and Testing

> [!NOTE]
> If `/default.vlc` is changed, these examples may need to be updated to reflect any backend domain changes.

The notes here should help guide you through recreating the steps needed to run
this locally using Docker. A [local Docker
setup](https://docs.docker.com/engine/install/) should provide fast feedback
for introducing changes and observing behavior.

This will set up two containers - nginx & varnish -which should provide the
majority of the pieces needed for testing varnish in isolation. The nginx
container will be used to simulate a frontend load balancer receiving initial
requests and reverse proxying the requests to Varnish just like a cloud load
balancer would. The nginx container will also be setup to provide mock HTTP
responses mimicing a backend application that Varnish is intended to be caching
requests for.

Requests from the docker host:
```
[docker host (80, 443)]
|
\-> [nginx lb (80, 443)]
    |
    \-> [docker host (9000)]
        |
        \-> [varnish (9000)]
            |
            \-> [nginx backend (4000)]
```


Responses from the nginx backend:
```
[nginx backend (4000)]
|
\-> [varnish (9000)]
    |
    \-> [docker host (9000)]
        |
        \-> [nginx lb (80, 443)]
            |
            \-> [docker host (80, 443)]
```



## Setup Requirements

While the examples here are expected to work in other environments, they were
created and tested on macOS Sequoia (15) and Docker Desktop.

These examples all expects IPv6 to be there and just work (even if your local
network is all IPv4). The `docker network ls` command doesn't show if a network
is IPv6 or not by default, but you can see these additional details if you
change the output format (example: `docker network ls --format json | jq .`).

Check to see if you have an existing IPv6 network for Docker to use. In these
examples we use the network `ip6net` so you may need to substitute that network
name if yours is different.

```bash
docker network ls --format 'table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}\t{{.IPv6}}'
```

If you don't have an IPv6 network you would need to create one

```bash
docker network create --ipv6 ip6net
docker network inspect ip6net
```



## Build containers

Build some containers using Docker for experimenting with locally:

```bash
NGINX_APP_NAME="dev-nginx"
NGINX_IMAGE="${NGINX_APP_NAME}:$(date +'%F.%H-%M-%S')"
rg FROM dev-nginx.Dockerfile | awk '{ print $2 }'
docker buildx build -f dev-nginx.Dockerfile . --tag "${NGINX_IMAGE}" --tag "${NGINX_APP_NAME}:latest"

VARNISH_APP_NAME="dev-varnish"
VARNISH_IMAGE="${VARNISH_APP_NAME}:$(date +'%F.%H-%M-%S')"
rg FROM Dockerfile | awk '{ print $2 }'
rg FROM dev-varnish.Dockerfile | awk '{ print $2 }'
docker buildx build -f dev-varnish.Dockerfile . --tag "${VARNISH_IMAGE}" --tag "${VARNISH_APP_NAME}:latest"

echo "
NGINX_APP_NAME=${NGINX_APP_NAME}
NGINX_IMAGE=${NGINX_IMAGE}
VARNISH_APP_NAME=${VARNISH_APP_NAME}
VARNISH_IMAGE=${VARNISH_IMAGE}
"

# List docker images
docker image list
```



## Run containers

Helpful commands to prepare for starting the containers:

```bash
# zsh command to ignore comments
setopt INTERACTIVE_COMMENTS

# Check for any running containers
docker container list
```

> [!NOTE]
> Environment variables can be passed into the nginx container which will build
> a custome nginx config based on the included template file

Start the nginx container, then get the network ipv4 and ipv6 address of the
container after it has been started:

```bash
NGINX_LB_HOST="pipedream.changelog.com nginx"
NGINX_LB_PROXY_PASS="http://172.17.0.1:9000"
NGINX_BACK_PORT=4000
NGINX_BACK_HOST="changelog-2024-01-12.fly.dev"
NGINX_BACK_REV_PROXY_LOC_MATCH="/feed"
NGINX_BACK_REV_PROXY="http://feeds.changelog.place/feed.xml"

# Start up nginx connecting it to the ipv6 brdige
# This may produce a couple errors that can be ignored if there isn't an
# existing container running that it tries to stop or remove, but it should
# proceed to creating a new container
(docker container stop dev-nginx || true) \
   && (docker container rm dev-nginx || true) \
   && docker run -d --network ip6net -p 80:80 -p 443:443 -p 4000:4000 -v ${PWD}/dev-nginx.conf.template:/etc/nginx/templates/default.conf.template --name dev-nginx \
      -e NGINX_LB_HOST="${NGINX_LB_HOST}" \
      -e NGINX_LB_PROXY_PASS="${NGINX_LB_PROXY_PASS}" \
      -e NGINX_BACK_PORT="${NGINX_BACK_PORT}" \
      -e NGINX_BACK_HOST="${NGINX_BACK_HOST}" \
      -e NGINX_BACK_REV_PROXY_LOC_MATCH="${NGINX_BACK_REV_PROXY_LOC_MATCH}" \
      -e NGINX_BACK_REV_PROXY="${NGINX_BACK_REV_PROXY}" \
      dev-nginx:latest

# Get the nginx container IPv4 and IPv6 addresses and backend domain
nginx_container_ip4=$(docker container inspect dev-nginx | jq -r '.[0].NetworkSettings.Networks.ip6net.IPAddress')
nginx_container_ip6=$(docker container inspect dev-nginx | jq -r '.[0].NetworkSettings.Networks.ip6net.GlobalIPv6Address')
backend_host_domain="changelog-2024-01-12.internal"

# See the results of the variables
echo "
nginx_container_ip4=${nginx_container_ip4}
nginx_container_ip6=${nginx_container_ip6}
backend_host_domain=${backend_host_domain}
"

# View the nginx config constructed from the template file
docker exec --user root dev-nginx /bin/bash -c 'cat /etc/nginx/conf.d/default.conf '
```

> [!NOTE]
> Environment variables can be passed into the varnish container for detail
> about the backend domain and IP addresses to override DNS responses with
> dnsmasq configs.

Start the varnish container, update the dnsmasq config if needed, then start dnsmasq:
```bash
# Start the varnish container and change dns resolver to use localhost
# (expecting dnsmasq to start shortly after the container is started).
(docker container stop dev-varnish || true) \
   && (docker container rm dev-varnish || true) \
   && docker run -d --network ip6net -p 9000:9000 -v ${PWD}/default.vcl:/etc/varnish/default.vcl --dns "127.0.0.1" --name dev-varnish \
      -e VARNISH_BACKEND_DOMAIN="${backend_host_domain}" \
      -e VARNISH_BACKEND_IPV4="${nginx_container_ip4}" \
      -e VARNISH_BACKEND_IPV6="${nginx_container_ip6}" \
      dev-varnish:latest

# Update the /etc/dnsmasq.conf file if environment variables passed into the
# container are different from the ones set by default in the container
# image's dev-varnish.Dockerfile.
docker exec --user root dev-varnish /bin/bash -c 'sed -i -r "s|^address=/([A-Za-z0-9.-]+)/([0-9.]+)\s*$|address=/${VARNISH_BACKEND_DOMAIN}/${VARNISH_BACKEND_IPV4}|" /etc/dnsmasq.conf'
docker exec --user root dev-varnish /bin/bash -c 'sed -i -r "s|^address=/([A-Za-z0-9.-]+)/([A-Fa-f:0-9]+)\s*$|address=/${VARNISH_BACKEND_DOMAIN}/${VARNISH_BACKEND_IPV6}|" /etc/dnsmasq.conf'
docker exec --user root dev-varnish /bin/bash -c 'tail /etc/dnsmasq.conf -n 2'

# Start up dnsmasq operating at 127.0.0.1 to override dns resolution
# This is necessary to override the DNS response provided to the vmod so that
# it instead sends backend requests to the nginx container (mock bacckend).
docker exec --user root dev-varnish /bin/bash -c "/etc/init.d/dnsmasq systemd-exec"
```

While varnish doesn't output much of anything to STDOUT you can see what it
does from the docker logs. Tailing the output from the `dev-nginx` container
will show you the access logs of requests hitting nginx.

```bash
# view initial varnish logs and then watch the nginx logs
docker logs dev-varnish
docker logs -f dev-nginx
```



## Run tests locally

Initialize the varnish dynamic backends with an HTTP request then check the
varnish backend list to see if probes are healthy:

```bash
curl -sk -D - https://localhost/
docker exec dev-varnish /bin/bash -c "varnishadm backend.list"
```

Run the test suite against the local containers:

```bash
# We need to pass the `--insecure` option because the nginx mock lb uses a self-signed cert
hurl --test --color --report-html tmp --insecure --variable host="https://127.0.0.1" test/*.hurl
```



## Example Test Results

Spinning this all up, bouncing requests back and forth, and manipulation dns
queries may feel like dark magic but it seemed to provide a majority of the
necessary componets for testing it all locally.

There are still a few (3) assertions failing on the `test/admin.hurl` portion.
This likely needs some adjustments to the backend nginx responses.

```
$ hurl --test --color --report-html tmp --insecure --variable host="https://127.0.0.1" test/*.hurl

error: Assert failure
  --> test/admin.hurl:10:0
   |
   | GET {{proto}}://{{host}}/admin
   | ...
10 | header "age" == "0" # NOT stored in cache
   |   actual:   string <1213>
   |   expected: string <0>
   |

error: Assert failure
  --> test/admin.hurl:11:0
   |
   | GET {{proto}}://{{host}}/admin
   | ...
11 | header "cache-status" contains "hits=0" # double-check that it's NOT stored in cache
   |   actual:   string <Edge; ttl=-1153.423; grace=86400.000; hit; stale; hits=1; region=>
   |   expected: contains string <hits=0>
   |

error: Assert failure
  --> test/admin.hurl:12:0
   |
   | GET {{proto}}://{{host}}/admin
   | ...
12 | header "cache-status" contains "miss" # NOT served from cache
   |   actual:   string <Edge; ttl=-1153.423; grace=86400.000; hit; stale; hits=1; region=>
   |   expected: contains string <miss>
   |

test/admin.hurl: Failure (1 request(s) in 36 ms)
test/homepage.hurl: Success (2 request(s) in 38 ms)
test/feed.hurl: Success (3 request(s) in 67049 ms)
--------------------------------------------------------------------------------
Executed files:    3
Executed requests: 6 (0.1/s)
Succeeded files:   2 (66.7%)
Failed files:      1 (33.3%)
Duration:          67052 ms
```



## Interacting with and exploring inside the containers

Exec into each of the containers to run commands locally:

```bash
docker exec -it --user root dev-varnish bash
docker exec -it --user root dev-nginx bash
```

If you need some additional tools inside the container:

```bash
apt update && apt -y install curl net-tools vim iproute2 dnsutils procps iputils-ping
```

Useful commands to use inside the Varnish container:

```bash
# swap out VCL configs (https://ma.ttias.be/reload-varnish-vcl-without-losing-cache-data/)
TIME=$(date +%s)
varnishadm vcl.load varnish_$TIME /etc/varnish/default.vcl
varnishadm vcl.use varnish_$TIME

# reload varnish configs
varnishreload

# All the varnish events
varnishlog

# View the backends, resolved addresses, and probe health status
varnishadm backend.list

# Monitoring vmod-dynamic with varnishlog
# This will show you the DNS resolution that is occurring when the vmod is trying
# to dynamically resolve the domain for the backends. If the varnish config has an
# acl for only allowing IPv6 addresses, you will see errors when it gets an IPv4
# response from the dns query.
varnishlog -g raw -q '* ~ vmod-dynamic'

# Additional useful details to display from Varnish
varnishadm vcl.list
varnishadm param.show
varnishadm storage.list
```

Check the various nginx endpoints from docker host:

```bash
# mock lb to varnish
curl -sv http://localhost:80/
curl -skv https://localhost:443/

# mock backend app
curl -sv http://localhost:4000/
curl -sv http://localhost:4000/podcast/feed
curl -sv http://localhost:4000/admin
curl -sv http://localhost:4000/feed

# varnish
curl -sv http://localhost:9000/

# testing full response (mock lb -> varnish -> mock backend)
curl -skv https://localhost/
curl -skv https://localhost/podcast/feed
curl -skv https://localhost/admin
curl -skv https://localhost/feed

# fake a call to pipedream.changelog.com that is actually routed to the local mock lb and handled locally
curl_domain="pipedream.changelog.com"
curl_ip_address="127.0.0.1"
curl_port="443"
curl_proto="https"
curl -sk -o /dev/null -D - --resolve "${curl_domain}:${curl_port}:${curl_ip_address}" "${curl_proto}://${curl_domain}:${curl_port}"
```



## Troubleshooting and Misc

If the docker containers fail to run you can remove the `-d` flag on the
`docker run` command to see the output and likely potential error produced when
starting it up.

Troubleshooting requests from inside the varnish container:

```bash
# display dnsmasq configs
cat /etc/dnsmasq.conf

# check dnsmasq configs
dnsmasq --test

# look for open ports the container is listening on
ss -tulpn | grep 53
netstat -tulpn

# Look at how dnsmasq expects to run with systemd
cat /lib/systemd/system/dnsmasq.service

# Start the dnsmasq process
/etc/init.d/dnsmasq systemd-exec

# Display the system's DNS resolver
vi /etc/resolv.conf

# query the dnsmasq configured overridden dns entries
# use system configured dns resolver
dig changelog-2024-01-12.internal
dig changelog-2024-01-12.internal aaaa
# send dns queries directly to localhost
dig changelog-2024-01-12.internal @127.0.0.1
dig changelog-2024-01-12.internal aaaa @127.0.0.1
# send dns queries directly to google dns
dig changelog-2024-01-12.internal @8.8.8.8
dig changelog-2024-01-12.internal aaaa @8.8.8.8

# send curl requests directly to nginx mock container
curl -sv -4 http://changelog-2024-01-12.fly.dev:4000/
curl -sv 'http://172.18.0.2/'
curl -sv 'http://172.18.0.2:4000/'
curl -sv -6 http://changelog-2024-01-12.fly.dev:4000/
curl -sv 'http://[fd20:b007:398e::2]/'
curl -sv 'http://[fd20:b007:398e::2]:4000/'

# check running processes
ps aux

# stop dnsmasq
/bin/kill $(cat /run/dnsmasq/dnsmasq.pid)
```

Misc Docker Commands:

```bash
# List the running docker containers
docker ps

# This will show stopped containers in addition to the running ones
docker container list --all

# If there is a stopepd container and you want to remove it
docker remove dev-nginx

# This shows the images docker has locally
docker image list

# If you've built a bunch of docker images it may be useful to prune the old ones
docker image prune --all

# Get info from docker about containers
docker container inspect varnish
docker container inspect nginx

# extract some details from the docker containers
echo "docker_host_ip4=$(docker container inspect varnish | jq -r '.[0].NetworkSettings.Networks.ip6net.Gateway')"
echo "docker_host_ip6=$(docker container inspect varnish | jq -r '.[0].NetworkSettings.Networks.ip6net.IPv6Gateway')"
echo "varnish_container_ip4=$(docker container inspect varnish | jq -r '.[0].NetworkSettings.Networks.ip6net.IPAddress')"
echo "varnish_container_ip6=$(docker container inspect varnish | jq -r '.[0].NetworkSettings.Networks.ip6net.GlobalIPv6Address')"

echo "docker_host_ip4=$(docker container inspect nginx | jq -r '.[0].NetworkSettings.Networks.ip6net.Gateway')"
echo "docker_host_ip6=$(docker container inspect nginx | jq -r '.[0].NetworkSettings.Networks.ip6net.IPv6Gateway')"
echo "nginx_container_ip4=$(docker container inspect nginx | jq -r '.[0].NetworkSettings.Networks.ip6net.IPAddress')"
echo "nginx_container_ip6=$(docker container inspect nginx | jq -r '.[0].NetworkSettings.Networks.ip6net.GlobalIPv6Address')"
```
