# https://github.com/dagger/dagger/releases

[private]
DAGGER_VERSION := "0.19.8"

# Use ghcr.io to work around:
#
# Error response from daemon: Get "https://registry.dagger.io/v2/": context
# deadline exceeded (Client.Timeout exceeded while awaiting headers)
[private]
export _EXPERIMENTAL_DAGGER_RUNNER_HOST := "docker-image://ghcr.io/dagger/engine:v" + DAGGER_VERSION

[private]
DAGGER_DIR := BIN_PATH / "pipely-dagger-" + DAGGER_VERSION

[private]
DAGGER := env("DAGGER_BIN", DAGGER_DIR / "dagger")

[private]
dagger *ARGS:
  @[ -x {{ DAGGER }} ] \
  || (curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR={{ DAGGER_DIR }} DAGGER_VERSION={{ DAGGER_VERSION }} sh)
  {{ if ARGS != "" { DAGGER + " " + ARGS } else { DAGGER + " --help" } }}
