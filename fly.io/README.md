# Rolling out a new instance

- Ensure that all GitHub workflows use the new instance
- Ensure that all production acceptance tests pass locally

To test that everything will work as it should, after running `j publish` locally, in `fly.io/cdn-2025-12-06` run the following:
- `j create` & update the dedicated IPv4 address in the top-level `justfile` (hint: `--resolve`)
- `j deploy <IMAGE_TAG>`
- `j scale`
- `j cert-add changelog.com` & update `_acme-challenge.changelog.com` DNS
- `j cert-add www.changelog.com` & update `_acme-challenge.www.changelog.com` DNS
- `j cert-add cdn.changelog.com` & update `_acme-challenge.cdn.changelog.com` DNS
- `j cert-add nightly.changelog.com` & update `_acme-challenge.nightly.changelog.com` DNS
- `j test-acceptance-production`

After committing, pushing & merging:
- `j tag v1.1.0 SHA 554`
- Update `PIPEDREAM_HOST` in e.g. `fly.io/changelog-2025-05-05/fly.toml`
- Update `A` & `AAAA` DNS records for all domains

Remember to delete the old instance / DNS records at least a week after the new production instance proves itself.