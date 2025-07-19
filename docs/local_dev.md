# Local Development and Testing

You can start up a local instance of Pipely by running `just local-debug`. Once the container is built it will be started up with the name `pipely-debug` and you will be in a shell. From there, you have all the tools you need to run and experiment.

## Available Tools

The following tools are available inside the container:

- hurl - HTTP testing tool
- httpstat - HTTP request statistics
- htop - Process monitor
- gotop - System monitor
- oha - HTTP load testing
- jq - JSON processor
- neovim - Text editor
- varnish tools - varnishadm, varnishlog, varnishtop, varnishstat
- sasqwatch - Varnish log analysis
- just - Task runner (available via container.justfile)

## Available Commands

Like the project, the development container has its own `just` file to run several useful operations. Simply type `just` to view all your options.

## Running the Server

To work effectively on the container, you're going to want to start up tmux. This will allow you to run the server in one window, other commands in other windows, and to switch between them quickly and easily.

If you're not familiar with tmux, I highly recommend taking a quick tutorial, but to jump right in:

- Get into the local container with `just local-debug`.
- type `tmux`.
- Start the server with `just up`.
- Create a new window by pressing `ctrl-b` followed by `c`.
- Try fetching the front page from the locally running server with `curl http://localhost:9000`.
- Run a benchmark test such as `just bench-app-4-pipedream`.
- Switch back to the other window and check out the live logs feed with `ctrl-b b`.
- Quit the server with `ctrl-c`.
- Close your two tmux windows with `exit` and `exit`.
- Close your container prompt with `exit` again.

## Architecture

```
[localhost:9000]
     ↓
[Varnish Cache] ← health checks backends
     ↓
[Dynamic Backend Selection]
     ↓
┌─────────────────┬─────────────────┬──────────────────┐
│   App Proxy     │  Feeds Proxy    │  Assets Proxy    │
│ (localhost:5000)│ (localhost:5010)│ (localhost:5020) │
│       ↓         │       ↓         │        ↓         │
│ TLS Terminator  │ TLS Terminator  │ TLS Terminator   │
│       ↓         │       ↓         │        ↓         │
│  External App   │ External Feeds  │ External Assets  │
└─────────────────┴─────────────────┴──────────────────┘
```

## Troubleshooting and Misc

The `/justfile` contains the commands listed when you run `just` from the host. There is a separate `/container/justfile` that is used for the commands available inside the application container when you run the `just` command.

From the shell, to see what command a just recipie would call use the `-n` flag with the `just` command. The `-n` or `--dry-run` option will print the command without running it.
```bash
just -n cache
just -n local-run
```

The Pipely application can be launched in one shell

```bash
just local-run
```

Then from a separate shell on the host, establish a shell into the nested container where the Pipely application is running.

```bash
# Exec into nested container (broken down)
docker_container_name="$(docker ps --format json | jq --slurp -r '[.[] | select((.Command | contains("dagger")) and (.Image | contains("dagger")) and (.Names | contains("dagger")))][0].Names')"
nested_containers="$(docker exec "${docker_container_name}" runc list -f json)"
nested_container_id="$(echo -E "${nested_containers}" | jq -r  '[.[] | select(.status=="running" and (.bundle | contains("dagger/worker/executor")))][0].id')"
docker exec -it "${docker_container_name}" runc exec -t "${nested_container_id}" bash

# Crazy One-Liner to shell into nested container
docker exec -it "$(docker ps --format json | jq --slurp -r '[.[] | select((.Command | contains("dagger")) and (.Image | contains("dagger")) and (.Names | contains("dagger")))][0].Names')" runc exec -t "$(echo -E "$(docker exec "$(docker ps --format json | jq --slurp -r '[.[] | select((.Command | contains("dagger")) and (.Image | contains("dagger")) and (.Names | contains("dagger")))][0].Names')" runc list -f json)" | jq -r  '[.[] | select(.status=="running" and (.bundle | contains("dagger/worker/executor")))][0].id')" bash
```

From within the application container additional tools can be used to diagnose and troubleshoot the environment

```bash
# Monitor the full details of all the varnish events
varnishlog

# Monitoring vmod-dynamic with varnishlog
# This will show you the DNS resolution that is occurring when the vmod is trying
# to dynamically resolve the domain for the backends. If the varnish config has an
# acl for only allowing IPv6 or IPv4 addresses, you will see errors when it gets a
# response from the dns query that is not part of the acl.
varnishlog -g raw -q '* ~ vmod-dynamic'

# Tail Varnish backend_health
varnishlog -g raw -i backend_health
# or use the recipie provided in the container's justfile
just health

# review the processes within the application container
ps -eo user,pid,ppid,%cpu,%mem,stat,start,time,cmd --forest
```

## Max Mind GeoIP Database for Log Enrichment

If you want to work with the geoip data used by vector to enrich log data, you can get a license key from maxmind in order to download the geoip database files.

https://dev.maxmind.com/geoip/geolite2-free-geolocation-data/#sign-up-for-a-maxmind-account-to-get-geolite
https://www.maxmind.com/en/geolite-free-ip-geolocation-data
My Account -> Manage License Keys

When some `just` commands call dagger they may pass in an option with the location of maxmind auth credentials to be retrieved from a 1Password vault `op://pipely/maxmind/credential` where secrets can be managed securely.

justfile
```justfile
# Debug production container locally - assumes envrc-secrets has already run
[group('team')]
local-production-debug:
    @PURGE_TOKEN="local-production" \
    just dagger call --beresp-ttl=5s \
      --honeycomb-dataset=pipely-dev --honeycomb-api-key=op://pipely/honeycomb/credential \
      --max-mind-auth=op://pipely/maxmind/credential \
      --purge-token=env:PURGE_TOKEN \
        local-production terminal --cmd=bash
```

There is a section of the dagger code that downloads the maxmind database using a license key.

dagger/main.go
```go
		geoLite2CityArchive := dag.HTTP("https://download.maxmind.com/geoip/databases/GeoLite2-City/download?suffix=tar.gz", dagger.HTTPOpts{
			AuthHeader: maxMindAuth,
		})
```

Dagger passes AuthHeader details to the URL so that it can authenticate with basic user credentials. The value kept in 1Password is expected to be in a raw header format.
https://github.com/dagger/dagger/blob/18701532b7a268ba42b542dff0fed0ce3db21419/core/schema/http.go#L84

The raw authorization header for basic authentication is a base64 encoded value that contains the username separated by a `:` and then the password.

```bash
curl -v -u YOUR_ACCOUNT_ID:YOUR_LICENSE_KEY https://download.maxmind.com/ 2>&1 | grep Authorization
# > Authorization: Basic WU9VUl9BQ0NPVU5UX0lEOllPVVJfTElDRU5TRV9LRVk=
echo "WU9VUl9BQ0NPVU5UX0lEOllPVVJfTElDRU5TRV9LRVk=" | base64 -d
```

To generate the value that needs to be stored in 1Password it should include `Basic ` followed by the base64 encoded credentials.
```bash
echo "Basic $(echo -n "YOUR_ACCOUNT_ID:YOUR_LICENSE_KEY" | base64)"
```

This value can be put into 1Password at `op://pipely/maxmind/credential` which relates to a `pipely` vault, and an item named `maxmind` with a custom password field named `credential`.

## Honeycomb Credentials

It is possible to create an entry in 1Password to satisfy some dagger calls attempting to pull the secret for `op://pipely/honeycomb/credential` even if the credential is invalid.
