# Pipely™ - single-purpose, single-tenant CDN

Based on [Varnish Cache](https://varnish-cache.org/releases/index.html). This started as the simplest CDN running on [fly.io](https://fly.io/changelog)
for [changelog.com](https://changelog.com)

You are welcome to fork this and build your own - OSS FTW 💚

## How it started

![How it started](./how-it-started-changelog-friends-38.png)

> 🧢 Jerod Santo - March 29, 2024 - <a href="https://changelog.com/friends/38#transcript-208" target="_blank">Changelog & Friends #38</a>

## The Roadmap to `v2.0`

- ✅ Tag & ship `v1.1`
  - ✅ Log & forward original `fly-request-id` header - [PR #42](https://github.com/thechangelog/pipely/pull/42)
  - ✅ Support websocket connections - [PR #43](https://github.com/thechangelog/pipely/pull/43)
  - ✅ Store MP3s in file cache + HOT & COLD instances - [PR #44](https://github.com/thechangelog/pipely/pull/44)
  - ✅ Update deps to latest stable (hold Varnish at `v7.7.3`) - [PR #45](https://github.com/thechangelog/pipely/pull/45)
  - ✅ Add nightly.changelog.com - [PR #46](https://github.com/thechangelog/pipely/pull/46)
  - ✅ Promote new `cdn-2025-12-06` production instance - [PR #47](https://github.com/thechangelog/pipely/pull/47)
- Tag & ship `v1.2`
  - ✅ Run periodic MP3, assets, feeds & nightly checks against all regions - [PR #48](https://github.com/thechangelog/pipely/pull/48)
  - ✅ Right-size `cdn-2025-12-06` + cleanup - [PR #49](https://github.com/thechangelog/pipely/pull/49)
  - ✅ Bump default memory pools - [PR #50](https://github.com/thechangelog/pipely/pull/50)
  - ✅ Add `x-forwarded-host` header to all backend requests - [PR #51](https://github.com/thechangelog/pipely/pull/51)
  - Include app-name in logs
- Tag & ship `v1.3`
  - Disable cookies for asset requests (ensure they always get served from cache)
  - Check URL `?args` impact on caching
  - Replace coproc with svlogd (a.k.a. overmind with runit)
  - TBD...

## What went into `v1.0`

- ✅ Static backend, 1 day stale, stale on error, `x`-headers - [Initial commit](https://github.com/thechangelog/pipely/commit/17d3899a52d9dc887efd7f49de92b24249431234)
- ✅ Dynamic backend, `cache-status` header - [PR #1](https://github.com/thechangelog/pipely/pull/1)
- ✅ Add tests - [PR #3](https://github.com/thechangelog/pipely/pull/3)
- ✅ Make it easy to develop locally - [PR #7](https://github.com/thechangelog/pipely/pull/7)
- ✅ Add support for TLS backends, publish & deploy to production - [PR #8](https://github.com/thechangelog/pipely/pull/8)
- ✅ Add Feeds backend - [PR #10](https://github.com/thechangelog/pipely/pull/10)
- ✅ Add Assets backend - [PR #11](https://github.com/thechangelog/pipely/pull/11)
- ✅ Send Varnish logs to Honeycomb.io - [PR #12](https://github.com/thechangelog/pipely/pull/12)
- ✅ Enrich Varnish logs with GeoIP data - [PR #13](https://github.com/thechangelog/pipely/pull/13)
- ✅ Supervisor restarts crashed processes - [PR #14](https://github.com/thechangelog/pipely/pull/14)
- ✅ Auth `PURGE` requests - [PR #16](https://github.com/thechangelog/pipely/pull/16)
- ✅ Add redirects from [Fastly VCL](./varnish/changelog.com.vcl) - [PR #19](https://github.com/thechangelog/pipely/pull/19)
- ✅ Send Varnish logs to S3 - [PR #27](https://github.com/thechangelog/pipely/pull/27)
- ✅ All contributors review & clean-up
  - Is the VCL as clean & efficient as it could be?
  - Does everything work as expected?
  - Anything that can be removed?
  - How do we make this friendlier to new users?
  - What would make this more contribution-friendly?
  - How easy is this to use as your own deployment?
- ✅ Tag & ship `v1.0-rc.1`
  - ✅ Update documentation and do some local dev tests - [PR #22](https://github.com/thechangelog/pipely/pull/22)
  - ✅ Add debug welcome message and prompt - [PR #25](https://github.com/thechangelog/pipely/pull/25)
  - ✅ Avoid using home_dir() due to Windows issues - [PR #26](https://github.com/thechangelog/pipely/pull/26)
  - ✅ Add troubleshooting and misc to local dev docs - [PR #29](https://github.com/thechangelog/pipely/pull/29)
- ✅ Tag & ship `v1.0-rc.2`
  - ✅ Prepare for 20% of the production traffic - [PR #30](https://github.com/thechangelog/pipely/pull/30)
  - Route 20% of the production traffic through
- ✅ Tag & ship `v1.0-rc.3`
  - ✅ Fix feeds URL rewrite - [PR #31](https://github.com/thechangelog/pipely/pull/31)
  - ✅ Increase instance size - [PR #32](https://github.com/thechangelog/pipely/pull/32)
- ✅ Tag & ship `v1.0-rc.4`
  - ✅ Limit Varnish memory to 66% (out of `3200M` out of `4000M`) - [3553723](https://github.com/thechangelog/pipely/commit/355372334b602a0ad55a96a85a288409ad4b8d84)
- ✅ Tag & ship `v1.0-rc.5`
  - ✅ Handle varnish-json-response failing on startup - [PR #33](https://github.com/thechangelog/pipely/pull/33)
  - ✅ Bump the instance size to performance-1x with 8GB of RAM - [PR #34](https://github.com/thechangelog/pipely/pull/34)
  - Route 50% of the production traffic through
- ✅ Tag & ship `v1.0-rc.6`
  - ✅ Add more locations - [PR #35](https://github.com/thechangelog/pipely/pull/35)
  - ✅ Increase backend timeout - [PR #36](https://github.com/thechangelog/pipely/pull/36)
- ✅ Tag & ship `v1.0-rc.7`
  - ✅ Update to Varnish v7.7.3 & Vector v0.49.0 - [PR #38](https://github.com/thechangelog/pipely/pull/38)
  - ✅ Support MP3 uploads - [PR #39](https://github.com/thechangelog/pipely/pull/39)
- ✅ Tag & ship `v1.0`
  - ✅ Update all dependencies to latest (hold Varnish at v7.7.3) - [PR #40](https://github.com/thechangelog/pipely/pull/40)
  - ✅ Route 100% of the production traffic through `v1.0`

## Local development and testing

While it's fun watching other people experiment with digital resin (varnish 😂), it's a whole lot more fun when you can repeat those experiments yourself, understand more how it works, and make your own modifications.

### Prerequisites

- 🐳 [Docker](https://docs.docker.com/engine/install/)
- 🤖 [Just](https://github.com/casey/just?tab=readme-ov-file#installation) version `1.35.0` or higher

And that's about it. Everything else is containerized with Dagger.

> [!NOTE]
>  **For Windows Developers:**
> The project's toolchain is made for Linux-like systems. On a Windows machine you will need to have the Windows Subsystem for Linux (WSL) installed in addition to Docker. `just` should be installed inside your WSL Linux operating system. You might be able to run Just natively from Windows, but there are some known bugs related to home directory filenames, so better to avoid that altogether and work directly in WSL.

```bash
just
Available recipes:
    check region="iad"                        # Check one region
    check-all                                 # Check all FLY_APP_REGIONS
    docker-bash                               # Open a shell in the docker container
    docker-run *ARGS                          # Run container in Docker (works on remote servers too): http://<DOCKER_HOST>:9000
    how-many-lines                            # How many lines of Varnish config?
    how-many-lines-raw                        # How many lines of Varnish config?
    http-profile url="https://changelog.com/" # Observe all HTTP timings - https://blog.cloudflare.com/a-question-of-timing
    local-debug                               # Debug container locally
    local-run                                 # Run container locally: available on http://localhost:9000
    test                                      # Test VTC + acceptance locally
    test-acceptance-local                     # Test acceptance local
    test-reports                              # Open test reports
    test-reports-rm                           # Clear test reports
    test-vtc                                  # Test VCL config

    [team]
    envrc-secrets                             # Create .envrc.secrets with credentials from 1Password
    local-debug-production                    # Debug production container locally - assumes envrc-secrets has already run
    local-run-production                      # Run production container locally - assumes envrc-secrets has already run - available on http://localhost:9000
    publish tag=_DEFAULT_TAG                  # Publish container image - assumes envrc-secrets was already run
    tag tag sha discussion                    # Tag a new release
    test-acceptance-production *ARGS          # Test acceptance production

# Run the tests
just test
```

## How can you help

If you have any ideas on how to improve this, please open an issue or go
straight for a pull request. We make this as easy as possible:
- All commits emphasize [good commit messages](https://cbea.ms/git-commit/) (more text for humans)
- This repository is kept small & simple (single purpose: build the simplest CDN on Fly.io)
- Slow & thoughtful approach - join our journey via [audio with transcripts](https://changelog.com/topic/kaizen) or [written](https://github.com/thechangelog/changelog.com/discussions/categories/kaizen)

See you in our [Zulip Chat](https://changelog.zulipchat.com/#narrow/channel/513743-pipely) 👋

> [!NOTE]
> Join from <https://changelog.com/~> . It requires signing up and requesting an invite before you can **Log in**

![Changelog on Zulip](./changelog.zulipchat.png)

## Contributors

- [Nabeel Sulieman](https://github.com/nabsul)
- [Matt Johnson](https://github.com/mttjohnson)
- [James A Rosen](https://www.jamesarosen.com/now)
- [Gerhard Lazu](https://gerhard.io)
