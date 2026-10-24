# Gavel PR quality gate

This repository runs **Gavel** on every pull request:

1. **`gavel-pr-check`** — `gavel pr-check` compares the PR head to the base commit and **fails only on new constitution violations** introduced by the change. Existing suite debt does not block the PR.
2. **`gavel-audit-sarif`** (informational) — whole-repo audit uploaded as SARIF when Code Scanning is available. Historical findings do not fail the job.

Pinned CLI: `@dsolisp/gavel@0.13.0` (no LLM in CI).

Docs: [PR_CHECK.md](https://github.com/dsolisp/gavel/blob/main/docs/PR_CHECK.md) · [ENTERPRISE.md](https://github.com/dsolisp/gavel/blob/main/docs/ENTERPRISE.md)

To require the check on the default branch: Settings → Branches → Branch protection → Require status checks → `gavel-pr-check`.
