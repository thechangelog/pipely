# vim: set tabstop=4 shiftwidth=4 expandtab:

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
HURL_VERSION := "6.0.0"
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

# Run the tests
test *ARGS: (hurl "--test --color --report-html tmp --variable host=https://pipedream.changelog.com " + ARGS + " test/*.hurl")

# Open the test report
report:
    open tmp/index.html

# Debug container image interactively
debug:
    @just dagger call debug terminal --cmd=bash

# https://github.com/dagger/dagger/releases

[private]
DAGGER_VERSION := "0.16.1"
[private]
DAGGER_DIR := BIN_PATH / "dagger-" + DAGGER_VERSION
[private]
DAGGER := DAGGER_DIR / "dagger"

[private]
dagger *ARGS:
    @[ -x {{ DAGGER }} ] \
    || (curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR={{ DAGGER_DIR }} DAGGER_VERSION={{ DAGGER_VERSION }} sh)
    {{ if ARGS != "" { DAGGER + " " + ARGS } else { DAGGER + " --help" } }}

# Publish container image
[group('team')]
publish tag="dev-$USER":
    @just dagger call --tag={{ tag }} \
        publish --registry-username=$USER --registry-password=op://pipely/ghcr/credential --image={{ FLY_APP_IMAGE }}

[private]
DAGGER_FLY_MODULE := "github.com/gerhard/daggerverse/flyio@flyio/v0.2.0"

# Deploy container image
[group('team')]
deploy tag="dev-$USER":
    @just dagger --mod={{ DAGGER_FLY_MODULE }} call \
        --token=op://pipely/fly/credential \
        --org={{ FLY_ORG }} \
            deploy --dir=. --image={{ FLY_APP_IMAGE }}:{{ tag }}

# Scale production app
[group('team')]
scale:
    flyctl scale count $(echo {{ FLY_APP_REGIONS }}, | grep -o ',' | wc -l) --max-per-region 1 --region {{ FLY_APP_REGIONS }} --app {{ FLY_APP }}

# Add cert $fqdn
[group('team')]
cert fqdn:
    flyctl certs add {{ fqdn }} --app {{ FLY_APP }}

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

# https://linux.101hacks.com/ps1-examples/prompt-color-using-tput/

[private]
_RESET := "$(tput sgr0)"
[private]
_GREEN := "$(tput bold)$(tput setaf 2)"
[private]
_MAGENTA := "$(tput bold)$(tput setaf 5)"
