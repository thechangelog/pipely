# Release failure recovery

Automatic GitHub-runner fallback remains available for non-release checks.
For a `v*` tag push, a failed Namespace run stops without automatic fallback.
The failure might happen after publication, deployment or production acceptance,
including during report upload. Repeating the whole workflow can repeat effects.

Before an operator-approved recovery:

1. Inspect the failed run and identify the last completed stage. A red workflow
   does not imply deployment failed or that nothing changed.
2. Verify published image identity and actual deployed state read-only. Preserve
   the run ID, commit, image digest and observed machines before deciding to act.
3. Select recovery for the incomplete stage. If deployment succeeded and only
   reporting failed, do not redeploy merely to obtain a green run.
4. Obtain approval for the exact recovery effects, then verify the result.

This guard does not make manual reruns, separate runs or tag pushes idempotent.
Do not use "Re-run all jobs" as an automatic recovery step. Production acceptance
also includes cache PURGE requests; it is not a read-only diagnostic.

When Namespace is not configured, GitHub remains the primary runner and can
perform a normal tag release. The change only restricts automatic fallback.

## Local scheduling-policy checks

`just test-workflows` uses Ruby 2.6+ with its standard-library YAML parser; no
third-party gems, secrets, container build or provider calls are needed. It is
also included in `just test`. These tests evaluate actual workflow predicates
against synthetic events and stage failures; they do not emulate GitHub's full
scheduler or prove cross-run exactly-once delivery.
