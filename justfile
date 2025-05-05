# vim: set tabstop=4 shiftwidth=4 expandtab:

set shell := ["bash", "-uc"]

[private]
default:
  @just --list

[private]
fmt:
  just --fmt --check --unstable
  just --version

[private]
OS := if os() == "macos" { "apple" } else { "unknown" }
[private]
OS_ALT := if os() == "macos" { "darwin" } else { "linux-gnu" }
[private]
LOCAL_PATH := home_dir() / ".local"
[private]
BIN_PATH := LOCAL_PATH / "bin"

# https://github.com/Orange-OpenSource/hurl/releases

[private]
HURL_VERSION := "6.1.1"
[private]
HURL_NAME := "hurl-" + HURL_VERSION + "-" + arch() + "-" + OS + "-" + OS_ALT
[private]
HURL := LOCAL_PATH / HURL_NAME / "bin" / "hurl"

[private]
hurl *ARGS:
  @[ -x {{ HURL }} ] \
  || (echo {{ _GREEN }}🔀 Installing hurl {{ HURL_VERSION }} ...{{ _RESET }} \
     && mkdir -p {{ BIN_PATH }} \
     && (curl -LSsf "https://github.com/Orange-OpenSource/hurl/releases/download/{{ HURL_VERSION }}/{{ HURL_NAME }}.tar.gz" | tar zxv -C {{ LOCAL_PATH }}) \
     && chmod +x {{ HURL }} && echo {{ _MAGENTA }}{{ HURL }} {{ _RESET }} && {{ HURL }} --version \
     && ln -sf {{ HURL }} {{ BIN_PATH }}/hurl && echo {{ _MAGENTA }}hurl{{ _RESET }} && hurl --version)
  {{ if ARGS != "" { HURL + " " + ARGS } else { HURL + " --help" } }}

# Test everything
test: test-vtc test-acceptance-local

# Test VCL config
test-vtc: (dagger 'call test-varnish stdout')

# Test local CDN
test-acceptance-local: (dagger 'call --beresp-ttl=5s test-acceptance-report export --path=./tmp/test-acceptance-local')

# Test remote CDN2 (a.k.a. Pipely, a.k.a. Pipedream)
test-acceptance-cdn2 *ARGS: (hurl "--test --color --report-html tmp/test-acceptance-cdn2 --continue-on-error --variable host=https://pipedream.changelog.com --variable assets_host=cdn2.changelog.com --variable delay_ms=65000 --variable delay_s=60 " + ARGS + " test/acceptance/*.hurl test/acceptance/cdn2/*.hurl")

# Test remote CDN
test-acceptance-cdn *ARGS: (hurl "--test --color --report-html tmp/test-acceptance-cdn --continue-on-error --variable host=https://changelog.com --variable assets_host=cdn.changelog.com " + ARGS + " test/acceptance/*.hurl test/acceptance/cdn/*.hurl")

# Open test reports
test-reports:
  open tmp/*/index.html

# Clear test reports
test-reports-rm:
  rm -fr tmp/*

# Debug container image interactively
debug: (dagger 'call --beresp-ttl=5s debug terminal --cmd=bash')

# https://github.com/dagger/dagger/releases

[private]
DAGGER_VERSION := "0.18.5"
[private]
DAGGER_DIR := BIN_PATH / "dagger-" + DAGGER_VERSION
[private]
DAGGER := DAGGER_DIR / "dagger"

[private]
dagger *ARGS:
  @[ -x {{ DAGGER }} ] \
  || (curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR={{ DAGGER_DIR }} DAGGER_VERSION={{ DAGGER_VERSION }} sh)
  {{ if ARGS != "" { DAGGER + " " + ARGS } else { DAGGER + " --help" } }}

# Open an interactive shell for high-level commands, e.g. `test`, `debug | terminal`, etc.
shell:
  @just dagger shell

# Observe all HTTP timings - https://blog.cloudflare.com/a-question-of-timing
http-profile url="https://pipedream.changelog.com/":
  @while sleep 1; do \
    curl -sL -o /dev/null \
      --write-out "%{url} http:%{http_version} status:%{http_code} {{ _WHITEB }}ip:%{remote_ip}{{ _RESET }} {{ _CYANB }}dns:%{time_namelookup}s{{ _RESET }} {{ _YELLOWB }}tcp:%{time_connect}s{{ _RESET }} {{ _MAGENTAB }}tls:%{time_appconnect}s{{ _RESET }} {{ _GREENB }}wait:%{time_starttransfer}s{{ _RESET }} {{ _BLUEB }}total:%{time_total}s{{ _RESET }}\n" \
    "{{ url }}"; \
  done

# How many lines of Varnish config?
how-many-lines:
  rg -c '' vcl/*.vcl

# How many lines of Varnish config?
how-many-lines-raw:
  rg -cv '^.*#|^\$' vcl/*.vcl

[private]
_DEFAULT_TAG := "dev-" + env("USER")

# Publish container image
[group('team')]
publish tag=_DEFAULT_TAG:
  @just dagger call --tag={{ tag }} \
      publish --registry-username=$USER --registry-password=op://pipely/ghcr/credential --image={{ FLY_APP_IMAGE }}

[private]
DAGGER_FLY_MODULE := "github.com/gerhard/daggerverse/flyio@flyio/v0.2.0"

# Deploy container image
[group('team')]
deploy tag=_DEFAULT_TAG: publish
  @just dagger --mod={{ DAGGER_FLY_MODULE }} call \
    --token=op://pipely/fly/credential \
    --org={{ FLY_ORG }} \
        deploy --dir=. --image={{ FLY_APP_IMAGE }}:{{ tag }}

# Scale production app
[group('team')]
scale:
  flyctl scale count $(echo {{ FLY_APP_REGIONS }}, | grep -o ',' | wc -l) --max-per-region 1 --region {{ FLY_APP_REGIONS }} --app {{ FLY_APP }}

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
    sleep 3; \
    flyctl machine start $machine \
    || (sleep 5; flyctl machine start $machine); \
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
FLY_ORG := env("FLY_ORG", "changelog")
[private]
FLY_APP := env("FLY_APP", "cdn-2025-02-25")
[private]
FLY_APP_IMAGE := env("FLY_APP_IMAGE", "ghcr.io/thechangelog/pipely")
[private]
FLY_APP_REGIONS := env("FLY_APP_REGIONS", "sjc,dfw,ord,iad,scl,lhr,fra,jnb,sin,syd")

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

# https://linux.101hacks.com/ps1-examples/prompt-color-using-tput/

[private]
_RESET := "$(tput sgr0)"
[private]
_GREEN := "$(tput bold)$(tput setaf 2)"
[private]
_MAGENTA := "$(tput bold)$(tput setaf 5)"
[private]
_WHITEB := "$(tput bold)$(tput setaf 7)"
[private]
_YELLOWB := "$(tput bold)$(tput setaf 3)"
[private]
_CYANB := "$(tput bold)$(tput setaf 6)"
[private]
_MAGENTAB := "$(tput bold)$(tput setaf 5)"
[private]
_GREENB := "$(tput bold)$(tput setaf 2)"
[private]
_BLUEB := "$(tput bold)$(tput setaf 4)"
