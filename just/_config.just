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
LOCAL_PATH := home_dir() / ".local"

[private]
BIN_PATH := LOCAL_PATH / "bin"

[private]
_DEFAULT_TAG := "dev-" + env("USER", "piper")

[private]
DAGGER_FLY_MODULE := "github.com/gerhard/daggerverse/flyio@flyio/v0.2.0"

[private]
FLY_ORG := env("FLY_ORG", "changelog")

[private]
FLY_APP := env("FLY_APP", "cdn-2025-02-25")

[private]
FLY_APP_IMAGE := env("FLY_APP_IMAGE", "ghcr.io/thechangelog/pipely")

[private]
FLY_APP_REGIONS := env("FLY_APP_REGIONS", "sjc,dfw,ord,iad,scl,lhr,fra,jnb,sin,syd")

[private]
export PURGE_TOKEN := env("PURGE_TOKEN", "local-purge")

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
