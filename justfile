# vim: set tabstop=4 shiftwidth=4 expandtab:

import 'just/_config.just'
import 'just/hurl.just'
import 'just/dagger.just'
import 'just/op.just'

[private]
default:
    @just --list

[private]
fmt:
    just --fmt --check --unstable
    just --version

# Debug container locally
local-debug:
    @just dagger call \
      --beresp-ttl=5s \
      --purge-token=env:PURGE_TOKEN \
      local-production terminal --cmd=bash

# Run container locally: available on http://localhost:9000
local-run:
    @just dagger call \
      --beresp-ttl=5s \
      --purge-token=env:PURGE_TOKEN \
        local-production as-service --use-entrypoint=true up

# Test VTC + acceptance locally
test: test-vtc test-acceptance-local

# Test VCL config
test-vtc:
    @just dagger call test-varnish stdout

# Test local setup
test-acceptance-local:
    @just dagger call \
      --beresp-ttl=5s \
      --purge-token=env:PURGE_TOKEN \
      test-acceptance-report export \
        --path=./tmp/test-acceptance-local

# Test NEW production - Pipedream, the Changelog variant of Pipely
[group('team')]
test-acceptance-pipedream *ARGS:
    HURL_purge_token="op://pipely/purge/credential" \
    just op run -- \
      just hurl --test --color --report-html tmp/test-acceptance-pipedream --continue-on-error \
        --variable host=https://pipedream.changelog.com \
        --variable assets_host=cdn2.changelog.com \
        --variable delay_ms=65000 \
        --variable delay_s=60 \
        {{ ARGS }} \
        test/acceptance/*.hurl test/acceptance/pipedream/*.hurl

# Test CURRENT production
test-acceptance-fastly *ARGS:
    @just hurl --test --color --report-html tmp/test-acceptance-fastly --continue-on-error \
      --variable proto=https \
      --variable host=changelog.com \
      --variable assets_host=cdn.changelog.com \
      {{ ARGS }} \
      test/acceptance/*.hurl test/acceptance/fastly/*.hurl

# Open test reports
test-reports:
    open tmp/*/index.html

# Clear test reports
test-reports-rm:
    rm -fr tmp/*

# Debug production container locally - assumes envrc-secrets has already run
[group('team')]
local-production-debug:
    @PURGE_TOKEN="local-production" \
    just dagger call --beresp-ttl=5s \
      --honeycomb-dataset=pipely-dev --honeycomb-api-key=op://pipely/honeycomb/credential \
      --max-mind-auth=op://pipely/maxmind/credential \
      --purge-token=env:PURGE_TOKEN \
        local-production terminal --cmd=bash

# Run production container locally - assumes envrc-secrets has already run - available on http://localhost:9000
[group('team')]
local-production-run:
    @PURGE_TOKEN="local-production" \
    just dagger call --beresp-ttl=5s \
      --honeycomb-dataset=pipely-dev --honeycomb-api-key=op://pipely/honeycomb/credential \
      --max-mind-auth=op://pipely/maxmind/credential \
      --purge-token=env:PURGE_TOKEN \
        local-production as-service --use-entrypoint=true up

# Observe all HTTP timings - https://blog.cloudflare.com/a-question-of-timing
http-profile url="https://pipedream.changelog.com/":
    @while sleep 1; do \
      curl -sL -o /dev/null \
        --write-out "%{url} http:%{http_version} status:%{http_code} {{ _WHITEB }}ip:%{remote_ip}{{ _RESET }} {{ _CYANB }}dns:%{time_namelookup}s{{ _RESET }} {{ _YELLOWB }}tcp:%{time_connect}s{{ _RESET }} {{ _MAGENTAB }}tls:%{time_appconnect}s{{ _RESET }} {{ _GREENB }}wait:%{time_starttransfer}s{{ _RESET }} {{ _BLUEB }}total:%{time_total}s{{ _RESET }}\n" \
      "{{ url }}"; \
    done

# How many lines of Varnish config?
how-many-lines:
    rg -c '' varnish/*.vcl

# How many lines of Varnish config?
how-many-lines-raw:
    rg -cv '^.*#|^\$' varnish/*.vcl

# Publish container image - assumes envrc-secrets was already run
[group('team')]
publish tag=_DEFAULT_TAG:
    @just dagger call --tag={{ tag }} --max-mind-auth=op://pipely/maxmind/credential \
        publish --registry-username=$USER --registry-password=op://pipely/ghcr/credential --image={{ FLY_APP_IMAGE }}

# Deploy container image
[group('team')]
deploy tag=_DEFAULT_TAG:
    @just dagger --mod={{ DAGGER_FLY_MODULE }} call \
      --token=op://pipely/fly/credential \
      --org={{ FLY_ORG }} \
          deploy --dir=. --image={{ tag }}

# Scale production app
[group('team')]
scale:
    flyctl scale count $(echo {{ FLY_APP_REGIONS }}, | grep -o ',' | wc -l) --max-per-region 1 --region {{ FLY_APP_REGIONS }} --app {{ FLY_APP }}

# Set app secrets - assumes envrc-secrets was already run
[group('team')]
secrets:
    PURGE_TOKEN="op://pipely/purge/credential" \
    HONEYCOMB_API_KEY="op://pipely/honeycomb/credential" \
    just op run -- bash -c 'flyctl secrets set --stage HONEYCOMB_API_KEY="$HONEYCOMB_API_KEY" PURGE_TOKEN="$PURGE_TOKEN"'
    flyctl secrets list

# Add cert $fqdn to app
[group('team')]
cert fqdn:
    flyctl certs add {{ fqdn }} --app {{ FLY_APP }}

# Show app certs
[group('team')]
certs:
    flyctl certs list --app {{ FLY_APP }}

# Show app IPs
[group('team')]
ips:
    flyctl ips list --app {{ FLY_APP }}

# Show app machines
[group('team')]
machines:
    flyctl machines list --app {{ FLY_APP }}

# Restart ALL app machines, one-by-one
[group('team')]
restart:
    @just machines \
    | awk '/pipely/ { print $1 }' \
    | while read machine; do \
      echo -en "\n♻️ "; \
      flyctl machine stop $machine; \
      sleep 10; \
      flyctl machine start $machine \
      || (sleep 10; flyctl machine start $machine); \
    done
    @echo {{ _MAGENTA }}🧐 Any stopped machines?{{ _RESET }}
    @just machines | grep stop || echo ✨

# Show app status
[group('team')]
status:
    flyctl status --app {{ FLY_APP }}

# Tag a new release
[group('team')]
tag tag sha discussion:
    git tag --force --sign --message="Discussed in <https://github.com/thechangelog/changelog.com/discussions/{{ discussion }}>" {{ tag }} {{ sha }}

# Create .envrc.secrets with credentials from 1Password
[group('team')]
envrc-secrets:
    op inject --in-file envrc.secrets.op --out-file .envrc.secrets

[private]
create:
    (flyctl apps list --org {{ FLY_ORG }} | grep {{ FLY_APP }}) \
    || flyctl apps create {{ FLY_APP }} --org {{ FLY_ORG }}

[private]
actions-runner:
    docker run --interactive --tty \
      --volume=pipely-linuxbrew:/home/linuxbrew/.linuxbrew \
      --volume=pipely-asdf:/home/runner/.asdf \
      --volume=.:/home/runner/work --workdir=/home/runner/work \
      --env=HOST=$(hostname) --publish=9090:9000 \
      --pull=always ghcr.io/actions/actions-runner

[private]
just0:
    curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin
