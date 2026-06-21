# AGENTS.md

Orientation for coding agents working on **Pipely** — a single-purpose,
single-tenant CDN for changelog.com: Varnish Cache 7.7.3 running on Fly.io.
Keep this file updated as the codebase evolves.

## Big picture

```text
client
└── DNS: DNSimple (A records → Fly dedicated IPv4 137.66.16.250)
    └── Fly.io proxy (app cdn-2025-12-06, 11 regions, 1 machine per region)
        └── container — processes supervised by overmind
            │           (Procfile generated in dagger/main.go:250)
            ├── varnishd :9000 — HTTP/2, malloc storage + optional file storage
            │   ├── app     → tls-exterminator :5000 → changelog-2025-05-05.fly.dev (Phoenix)
            │   ├── assets  → tls-exterminator :5010 → changelog.place (Cloudflare)
            │   ├── feeds   → tls-exterminator :5020 → feeds.changelog.place (Cloudflare)
            │   └── nightly → tls-exterminator :5030 → changelog-nightly-2023-10-10.fly.dev
            └── logs — varnish-json-response.bash (varnishncsa → JSON)
                       piped into Vector via a bash coproc
```

tls-exterminator exists because Varnish speaks plain HTTP: each backend
points at `localhost:<port>`, where the proxy adds TLS + SNI to the real
origin. Backend selection per request:

| Backend | Selected by                          |
|---------|--------------------------------------|
| app     | default — set unconditionally first  |
| assets  | `Host: cdn.changelog.com`            |
| feeds   | URL rules in `feeds-backend.vcl`     |
| nightly | `Host: nightly.changelog.com`        |

Backends are libvmod-dynamic directors (declared in
`varnish/vcl/default.vcl` `vcl_init`, ttl=10s DNS, health probes on
`/health`). The static default backend is disabled (`backend default none;`).

## VCL mechanics you must understand before editing

- `varnish/vcl/default.vcl` is the entrypoint; everything else is an
  `include`. Varnish **concatenates same-named subs in include order** —
  `app-backend.vcl` is included first, so its `vcl_recv` runs first and sets
  the app backend as the default; later includes (assets, feeds, nightly,
  redirects) override `req.backend_hint` when their conditions match.
- **No `vcl_recv` sub ever `return`s**, so the *builtin* `vcl_recv` runs
  last: any request with a `Cookie` or `Authorization` header is
  `pass`ed (never cached, `cache_status=pass`). Feeds & assets routes
  `unset` both headers (responses never vary on credentials there) so they
  always cache; app & nightly requests keep credentials and bypass the
  cache. Guarded by `test/vtc/credentials.vtc`.
- Feed URLs are **normalized** to the canonical `/<feed>.xml` form before
  hashing & fetching (query string dropped): `/feed` & `/rss` → `/feed.xml`,
  `/<pod>/feed` → `/<pod>.xml`, `/feeds/<x>` → `/<x>.xml`. Direct requests
  for the canonical form are routed to the feeds backend via an allowlist.
  Exception: the ++ feed is private, reachable only via its tokenized URL —
  `/plusplus.xml` is deliberately absent from the allowlist, the `/feeds/*`
  wildcard excludes it, and the rewrite to `/plusplus.xml` happens in
  `vcl_backend_fetch` so the token stays in the cache key (a token-less
  request can never hit the cached private feed). Guarded by
  `test/vtc/plusplus.vtc`.
- Per-backend cache policy lives in each file's `vcl_backend_response`,
  guarded by `bereq.http.x-backend-<name>` markers:
  - app & nightly: memory, ttl 1m / grace 1d / keep 7d
  - feeds: memory, ttl 12h / grace 1d / keep 7d
  - assets: ttl 1d / grace 2d / keep 7d; `.mp3` → `storage.disk`
    (file cache on the Fly volume) + `do_stream`; everything else memory
  - 5xx: uncacheable; bg-fetch 5xx → `abandon` so stale objects survive
    (`disable-caching-for-5xx.vcl`)
- `BERESP_TTL` / `BERESP_GRACE` / `BERESP_KEEP` env vars override all of the
  above (dev/test only — `just local-debug` sets ttl=5s).
- Other routing: `www.*` → 301 apex; `x-forwarded-proto: http` → 301 https;
  websocket upgrades → `pipe`; `PURGE` requires `Purge-Token` header matching
  `PURGE_TOKEN` env; `/health` → synth 204 (Fly health check);
  `/{app,assets,feeds,nightly}_health` → `pass` to that origin's `/health`;
  `/practicalai*` → 301 off-site; old news MP3 paths → 308 to
  cdn.changelog.com (`news-mp3.vcl`).
- `varnish/changelog.com.vcl` is the **legacy Fastly VCL, reference only**
  (source of ported redirects) — never deployed.
- Keep VCL lean: `just how-many-lines` counts effective lines; small & simple
  is an explicit project goal.

## Observability

- `vcl_deliver`/`vcl_synth` build the `cache-status` response header:
  `region=X; origin=Y; ttl=…; grace=…; keep=…; storage=…; hit|miss|bypass|synth; hits=N`.
  Acceptance tests assert on its parts — keep format stable.
- Every `std.log("key:value")` in VCL becomes a JSON field via the
  `varnishncsa` format string in `varnish/varnish-json-response.bash`
  (add new fields in both places).
- Vector pipeline (`vector/changelog.com/`): stdin JSON → GeoIP enrichment
  (MaxMind mmdb, only when built with `--max-mind-auth`) → Honeycomb sink +
  S3 sinks (JSON for feeds, CSV per podcast for MP3 stats).
- Honeycomb dataset: production `pipedream` (set via `just fly secrets`),
  local `pipedream-local` (.envrc); the dagger default `pipely` is unused in
  practice. S3 buckets `changelog-logs-*`, local suffix `-pipedream-local`.
- `x-request-id` echoes Fly's `fly-request-id`.
- `app_generation` & `region` (logged, and `region` is in `cache-status`)
  are read once in `vcl_init` from `FLY_APP_NAME` / `FLY_REGION`. Fly exposes
  `FLY_APP_NAME`, **not** `FLY_APP` — reading the latter logs the `NOW`
  fallback on every machine. Local/test fall back to `NOW` / `LOCAL`.

## Build, test, run (everything is `just` + Dagger)

Host prerequisites: Docker + just ≥1.35 only. Recipes self-install pinned
dagger/hurl/flyctl/op into `~/.local/bin` (versions pinned in `just/*.just`;
container tool versions pinned in `dagger/main.go` consts).

**Always go through the `just` recipes** — never invoke `docker`, `dagger`,
`varnishtest`, `hurl` or `flyctl` directly. The recipes pin versions and
encode the supported workflow. Only fall back to a raw command when no
recipe covers the need, and call that out explicitly when you do.

> Sandbox gotcha: Dagger resolves the module context via git and fails hard
> (`git config error: ... exit status 128`) if `.git` is present but broken
> — e.g. a worktree checkout whose parent repo isn't mounted (`.git` is a
> `gitdir:` pointer file, not a directory). Symptom: `just test`/`test-vtc`
> die at "go SDK: load runtime" before any test runs. Fix: make git valid,
> or move the dead `.git` pointer aside so Dagger treats the dir as plain
> files.

- `just test` — VTC + local acceptance (what CI runs on every PR)
- `just test-vtc` — `varnishtest` against `test/vtc/*.vtc` inside the
  container image
- `just test-acceptance-local` — hurl files in `test/acceptance/` against a
  containerized instance (service-bound as `pipely:9000`); HTML report
  exported to `tmp/`
- `just local-run` / `local-debug` — run/shell the container locally on :9000
  (the container has its own justfile: `container/justfile` — varnish tools,
  benchmarks, etc.)
- `just check-all` — periodic per-region production checks
  (`test/acceptance/periodic/region.hurl`, uses `Fly-Force-Region` header);
  also runs daily via `.github/workflows/check_all.yml`
- `[team]` recipes need 1Password: `just envrc-secrets` renders
  `.envrc.secrets` from `envrc.secrets.op` (direnv loads it)

### Writing tests

- VTC: each file mocks origins with `server s1 {…}`, sets backend env vars
  via `setenv`, re-declares the dynamic director **without a probe**, and
  includes only the VCL files under test plus
  `test/disable-caching-for-testing.vcl` and `disable-default-backend.vcl`.
  Mock servers consume requests **in order** — every client request needs a
  matching `rxreq/txresp` block.
- Routing changes need both: a VTC case (unit) and a hurl case (acceptance).
  Note `test/acceptance/feeds.hurl` asserts against production-shaped
  responses (`cf-ray` from Cloudflare origins, `age`, `content-type`).

## CI / deployment

- `.github/workflows/ship_it.yml`: PRs/pushes run `just test` on
  Namespace.so runners with a GitHub-runner fallback (`_namespace.yml` /
  `_github.yml` are identical in outcome). Pushing a `v*` tag additionally
  runs `just publish <tag>` (ghcr.io/thechangelog/pipely), `just deploy
  <tag>` in `fly.io/cdn-2025-12-06/`, then `just test-acceptance-production`.
- Release flow: `just tag <tag> <sha> <discussion-id>` (signed tag linking a
  GitHub discussion), push tag, CI does the rest. README tracks the roadmap
  per release — update it.
- Fly app `cdn-2025-12-06`, dedicated IPv4 `137.66.16.250` (acceptance tests
  `--resolve` against it). 11 regions; HOT regions (sjc,lax,iad,fra,nrt) are
  performance-2x/4GB, COLD are performance-1x/2GB; every machine has a 200GB
  `varnish_file_cache` volume. `VARNISH_SIZE` = 70% of RAM,
  `VARNISH_FILE_SIZE` = 90% of disk (set by `just deploy`/`scale`, see
  `just/fly.just`). Region/sizing config: `fly.io/cdn-2025-12-06/.envrc`.
- Fly proxy forces HTTP/1.1 via ALPN (`fly.toml`) to avoid response-body
  blocking (changelog.com issue #553); concurrency hard_limit 2700 ≈
  thread_pools(2) × thread_pool_max(1500) − 10%.
- New-instance rollout checklist: `fly.io/README.md`.

## Conventions

- Commit messages: descriptive, human-first (https://cbea.ms/git-commit/).
- Discussion happens in Zulip (#pipely) and Changelog "Kaizen" episodes;
  releases reference GitHub discussions.
- Docs are lean on purpose: `docs/local_dev.md` for local workflow,
  `fly.io/README.md` for rollouts, README for roadmap/history.
