set shell := ["bash", "-uc"]

[private]
OS := if os() == "macos" { "apple" } else { "unknown" }

[private]
OS_ALT := if os() == "macos" { "darwin" } else { "linux-gnu" }

[private]
OS_ALT2 := if os() == "macos" { "darwin" } else { "linux" }

[private]
ARCH_ALT := if arch() == "x86_64" { "amd64" } else { "arm64" }

[private]
LOCAL_PATH := "~/.local"

[private]
BIN_PATH := LOCAL_PATH / "bin"

[private]
APP_IMAGE := env("APP_IMAGE", "ghcr.io/thechangelog/pipely")

[private]
_DEFAULT_TAG := "dev-" + env("USER", "piper")

[private]
export PURGE_TOKEN := env("PURGE_TOKEN", "local-purge")

[private]
LOCAL_CONTAINER_IMAGE := env("LOCAL_CONTAINER_IMAGE", "pipely.dev:" + datetime("%Y-%m-%d"))
