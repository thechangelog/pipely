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
      --varnish-file-cache=true \
      local-production terminal --cmd=bash

# Run container locally: available on http://localhost:9000
local-run:
    @just dagger call \
      --purge-token=env:PURGE_TOKEN \
      --varnish-file-cache=true \
        local-production as-service --use-entrypoint=true up

# Run container in Docker (works on remote servers too): http://<DOCKER_HOST>:9000
docker-run *ARGS:
    @just dagger call \
      --purge-token=env:PURGE_TOKEN \
      --varnish-cache-size=1G \
      --varnish-file-cache=true \
      local-production export --path=tmp/{{ LOCAL_CONTAINER_IMAGE }}
    @docker rm --force pipely.dev
    @docker tag $(docker load --input=tmp/{{ LOCAL_CONTAINER_IMAGE }} | awk -F: '{ print $3 }') {{ LOCAL_CONTAINER_IMAGE }}
    @docker run --detach --network host --env PURGE_TOKEN=$PURGE_TOKEN --name pipely.dev {{ LOCAL_CONTAINER_IMAGE }}
    @docker container ls --filter name="pipely.dev" --format=json --no-trunc | jq .
    @rm -f tmp/{{ LOCAL_CONTAINER_IMAGE }}

# Open a shell in the docker container
docker-bash:
    @docker exec -it pipely.dev bash

# Test VTC + acceptance locally
test: test-vtc test-acceptance-local

# Test VCL config
test-vtc:
    @just dagger call test-varnish stdout

# Test acceptance local
test-acceptance-local:
    @just dagger call \
      --beresp-ttl=5s \
      --purge-token=env:PURGE_TOKEN \
      --varnish-file-cache=true \
      test-acceptance-report export \
        --path=./tmp/test-acceptance-local

# Test acceptance production
[group('team')]
test-acceptance-production *ARGS:
    HURL_purge_token="op://pipely/purge/credential" \
    just op run -- \
      just hurl --test --color --report-html tmp/test-acceptance-production --continue-on-error \
        --variable proto=https \
        --variable host=changelog.com \
        --resolve changelog.com:443:137.66.16.250 \
        --variable assets_host=cdn.changelog.com \
        --resolve cdn.changelog.com:443:137.66.16.250 \
        --variable nightly_host=nightly.changelog.com \
        --resolve nightly.changelog.com:443:137.66.16.250 \
        --variable delay_ms=65000 \
        --variable delay_s=60 \
        {{ ARGS }} \
        test/acceptance/*.hurl

# Check all FLY_APP_REGIONS
[parallel]
check-all http="1.1": (check "sjc" http) \
                      (check "lax" http) \
                      (check "iad" http) \
                      (check "lhr" http) \
                      (check "cdg" http) \
                      (check "ams" http) \
                      (check "fra" http) \
                      (check "sin" http) \
                      (check "nrt" http)

# Check one region
check region="iad" http="1.1" timeout="60":
    @echo "🧐 Checking {{ uppercase(region) }}..."
    @(just hurl --test --color --report-html tmp/check-all --continue-on-error \
      --connect-timeout 10 \
      --http{{ http }} \
      --max-time {{ timeout }} \
      --variable region={{ region }} \
      --variable host=changelog.com \
      --resolve changelog.com:443:137.66.16.250 \
      --variable assets_host=cdn.changelog.com \
      --resolve cdn.changelog.com:443:137.66.16.250 \
      --variable nightly_host=nightly.changelog.com \
      --resolve nightly.changelog.com:443:137.66.16.250 \
      test/acceptance/periodic/*.hurl \
      && echo -e "\033[1A✅ {{ uppercase(region) }}\n\u200B") \
    || (echo -e "\033[1A❌ {{ uppercase(region) }}\n\u200B" \
        && exit 69)

# Open test reports
test-reports:
    open tmp/*/index.html

# Clear test reports
test-reports-rm:
    rm -fr tmp/*

# Debug production container locally - assumes envrc-secrets has already run
[group('team')]
local-debug-production:
    @PURGE_TOKEN="local-production" \
    just dagger call \
      --honeycomb-dataset=${HONEYCOMB_DATASET} \
      --honeycomb-api-key=env:HONEYCOMB_API_KEY \
      --max-mind-auth=env:MAXMIND_AUTH \
      --purge-token=env:PURGE_TOKEN \
      --varnish-file-cache=true \
      --aws-region=${AWS_REGION} \
      --aws-local-production-s3-bucket-suffix=${AWS_S3_BUCKET_SUFFIX} \
      --aws-access-key-id=env:AWS_ACCESS_KEY_ID \
      --aws-secret-access-key=env:AWS_SECRET_ACCESS_KEY \
        local-production terminal --cmd=bash

# Run production container locally - assumes envrc-secrets has already run - available on http://localhost:9000
[group('team')]
local-run-production:
    @PURGE_TOKEN="local-production" \
    just dagger call \
      --honeycomb-dataset=${HONEYCOMB_DATASET} \
      --honeycomb-api-key=env:HONEYCOMB_API_KEY \
      --max-mind-auth=env:MAXMIND_AUTH \
      --purge-token=env:PURGE_TOKEN \
      --varnish-file-cache=true \
      --aws-region=${AWS_REGION} \
      --aws-local-production-s3-bucket-suffix=${AWS_S3_BUCKET_SUFFIX} \
      --aws-access-key-id=env:AWS_ACCESS_KEY_ID \
      --aws-secret-access-key=env:AWS_SECRET_ACCESS_KEY \
        local-production as-service --use-entrypoint=true up

# Observe all HTTP timings - https://blog.cloudflare.com/a-question-of-timing
http-profile url="https://changelog.com/":
    @while sleep 1; do \
      curl -sL -o /dev/null \
        --write-out "%{url} http:%{http_version} status:%{http_code} {{ BOLD }}{{ WHITE }}ip:%{remote_ip} {{ CYAN }}dns:%{time_namelookup}s {{ YELLOW }}tcp:%{time_connect}s {{ MAGENTA }}tls:%{time_appconnect}s {{ GREEN }}wait:%{time_starttransfer}s {{ BLUE }}total:%{time_total}s{{ NORMAL }}\n" \
      "{{ url }}"; \
    done

# How many lines of Varnish config?
how-many-lines:
    rg -cv '^.*#|^\$' varnish/vcl/*.vcl \
    | awk -F: '{sum += $2} END {print sum}'

# Publish container image - assumes envrc-secrets was already run
[group('team')]
publish tag=_DEFAULT_TAG:
    @just dagger call --varnish-file-cache=true --tag={{ tag }} --max-mind-auth=op://pipely/maxmind/credential \
        publish --registry-username=$USER --registry-password=op://pipely/ghcr/credential --image={{ APP_IMAGE }}

# Tag a new release
[group('team')]
tag tag sha discussion:
    git tag --force --sign --message="Discussed in <https://github.com/thechangelog/changelog.com/discussions/{{ discussion }}>" {{ tag }} {{ sha }}

# Create .envrc.secrets with credentials from 1Password
[group('team')]
envrc-secrets:
    just op inject --in-file envrc.secrets.op --out-file .envrc.secrets

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
