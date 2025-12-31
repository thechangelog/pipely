# https://github.com/superfly/flyctl/releases

import 'op.just'

[private]
FLYCTL_VERSION := "0.4.0"
[private]
FLYCTL_INSTALL := BIN_PATH / "pipely-flyctl-" + FLYCTL_VERSION
[private]
FLYCTL := env("FLYCTL_BIN", FLYCTL_INSTALL / "bin/flyctl")

[private]
flyctl *ARGS:
  @[ -x {{ FLYCTL }} ] \
  || (curl -fsSL https://fly.io/install.sh | FLYCTL_INSTALL={{ FLYCTL_INSTALL }} sh -s {{ FLYCTL_VERSION }} )
  {{ if ARGS != "" { "FLY_API_TOKEN=\"${FLY_API_TOKEN:-op://pipely/fly/" + FLY_APP + "}\" just op run -- " + FLYCTL + " " + ARGS } else { FLYCTL + " --help" } }}
