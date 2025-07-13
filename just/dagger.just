# https://github.com/dagger/dagger/releases

[private]
DAGGER_VERSION := "0.18.12"
[private]
DAGGER_DIR := BIN_PATH / "pipely-dagger-" + DAGGER_VERSION
[private]
DAGGER := env("DAGGER_BIN", DAGGER_DIR / "dagger")

[private]
dagger *ARGS:
  @[ -x {{ DAGGER }} ] \
  || (curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR={{ DAGGER_DIR }} DAGGER_VERSION={{ DAGGER_VERSION }} sh)
  {{ if ARGS != "" { DAGGER + " " + ARGS } else { DAGGER + " --help" } }}
