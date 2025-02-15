# Pipely™️

A single-purpose, single-tenant CDN for [changelog.com](https://changelog.com).
Runs [Varnish Cache](https://varnish-cache.org/releases/index.html) (open
source) on [Fly.io](https://fly.io/changelog). This repository exists for a
single reason: build the simplest CDN on [Fly.io](https://fly.io/changelog).
You are welcome to fork it and make it your own. OSS FTW 💚

## How it started

> I like the idea of having like this 20-line Varnish config that we deploy
> around the world, and it’s like “Look at our CDN, guys.”
>
> It’s so simple, and it can do exactly what we want it to do, and nothing
> more.
>
> But I understand that that’s a <strong>pipe dream</strong>, because that
> Varnish config will be slightly longer than 20 lines, and we’d run into all
> sorts of issues that we end up sinking all kinds of time into.
>
> 🧢 Jerod Santo - March 29, 2024 - <a href="https://changelog.com/friends/38#transcript-208" target="_blank">Changelog & Friends #38</a>

## How is it going (a.k.a. Roadmap)

- [x] Static backend, 1 day stale, stale on error, x-headers - [Initial commit](https://github.com/thechangelog/pipely/commit/17d3899a52d9dc887efd7f49de92b24249431234)
- [x] Dynamic backend, cache-status header - [PR #1](https://github.com/thechangelog/pipely/pull/1)
- [x] Add tests - [PR #3](https://github.com/thechangelog/pipely/pull/3)
- [x] Make it easy to develop locally - [PR #7](https://github.com/thechangelog/pipely/pull/7)
- [x] Add support for TLS backends, publish & deploy to production - [PR #8](https://github.com/thechangelog/pipely/pull/8)
- [ ] Add feeds backend: /feed -> https://feeds.changelog.place/feed.xml
- [ ] Send logs to Honeycomb.io (same structure as Fastly logs)
- [ ] Send logs to S3 (for stats)
- [ ] Implement purge across all app instances (Fly.io machines)
- [ ] Add edge redirects from [Fastly service](https://manage.fastly.com/configure/services/7gKbcKSKGDyqU7IuDr43eG)

## Local development and testing

While it's fun watching other people experiment with digital resin (varnish
😂), it's a whole lot more fun when you can repeat those experiments yourself,
understand more how it works, and make your own modifications.

You can find some instructions and notes for kicking the tires and [developing
& testing this locally](docs/local_dev.md).

A few other commands that you may be interested in:

```bash
# Requires https://github.com/casey/just
just
Available recipes:
    debug                   # Debug container image interactively
    report                  # Open the test report
    test *ARGS              # Run the tests

    [team]
    cert fqdn               # Add cert $fqdn
    deploy tag="dev-$USER"  # Deploy container image
    envrc-secrets           # Create .envrc.secrets with credentials from 1Password
    publish tag="dev-$USER" # Publish container image
    scale                   # Scale production app

# Run the tests
just test

# There is a script which precedes `just`
# Yes, we should combine them. Contributions welcome!
./run
First argument must be one of the following
deploy          → deploys to Fly.io
world-scale     → makes it World Scale™
small-scale     → makes it Small Scale™
http-detailed   → shows detailed http response
http-measure    → measures http response times
http-profile    → profiles http responses
demo-2024-01-26 → runs through the first demo
demo-2024-06-21 → runs through the second demo

💡 All following arguments are passed to the command
```

## How can you help

If you have any ideas on how to improve this, please open an issue or go
straight for a pull request. We make this as easy as possible:
- All commits emphasize [good commit messages](https://cbea.ms/git-commit/) (more text for humans)
- This repository is kept small & simple (single purpose: build the simplest CDN on Fly.io)
- Slow & thoughtful approach - join our journey via [audio with transcripts](https://changelog.com/topic/kaizen) or [written](https://github.com/thechangelog/changelog.com/discussions/categories/kaizen)

See you in our [Zulip Chat](https://changelog.zulipchat.com/) 👋

> [!NOTE]
> Join from <https://changelog.com/~> . It requires signing up and requesting an invite before you can **Log in**

![Changelog on Zulip](./changelog.zulipchat.png)

## Contributors

- [James A Rosen](https://www.jamesarosen.com/now), Staff Software Engineer
- [Matt Johnson](https://github.com/mttjohnson), Senior Site Reliability Engineer
- [Nabeel Sulieman](https://github.com/nabsul), Staff Software Engineer
