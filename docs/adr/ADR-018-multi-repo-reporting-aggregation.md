# ADR-018: Multi-Repo Reporting Aggregation (R2 + QA Dashboard)

**Status**: Accepted (Phase 15)
**Date**: 2026-05-05
**Deciders**: QA Architecture Team
**Related**: [ADR-016](./ADR-016-distributed-tracing-in-test-execution.md), [ADR-017](./ADR-017-consumer-driven-contract-testing-scope.md), [MODERNIZATION_PLAN.md](../../../MODERNIZATION_PLAN.md), [STANDARDS.md](../../STANDARDS.md)

---

## Context

The five consumer repos (Python, Java, Playwright, Cypress, C#) publish Allure HTML to Cloudflare R2 for portfolio review. We also need **machine-readable run metrics** in one place so a **single dashboard** can show an executive view across stacks without opening five Allure trees.

Goals:

- One object store prefix for **per-run JSON summaries** (distinct from Allure HTML trees).
- A **qa-dashboard** repo that aggregates those JSON files on a schedule and deploys a static site (GitHub Pages).

---

## Decision

### 1. Two R2 buckets (conceptual separation)

| Bucket | Purpose | Typical layout |
|--------|---------|----------------|
| `qa-portfolio-metrics` | Small JSON summaries for aggregation | `<repo-name>/<run-id>.json` or nested unique keys (e.g. matrix suite) |
| `qa-portfolio-allure` | Generated Allure HTML sites | `<repo-name>/<run-id>/` (and matrix subpaths where applicable) |

Access uses the **S3-compatible API** with `aws s3 cp` / `aws s3 sync` and endpoint `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`.

### 2. `summary.json` schema (consumer contract for qa-dashboard)

Produced by each repo’s `scripts/generate_summary_json.js` (copied from [shared-docs/templates/scripts/generate_summary_json.js](../../templates/scripts/generate_summary_json.js)). Minimum fields consumed by the dashboard builder:

| Field | Type | Notes |
|-------|------|--------|
| `repo` | string | Repository name (e.g. `PythonSeleniumProject`) |
| `run_id` | string | `GITHUB_RUN_ID` |
| `timestamp` | string | ISO-8601 |
| `suite` | string | Logical suite label (`full-tests` input, `nightly`, or matrix `suite`) |
| `total`, `passed`, `failed`, `broken`, `skipped` | number | Derived from Allure `*-result.json` |
| `duration_ms` | number | Sum of result durations |

**Environment variables** (align CI with script):

- `REPO_NAME` — usually `${{ github.event.repository.name }}`
- `GITHUB_RUN_ID` — set automatically on GitHub Actions runners; script falls back for local runs
- `TEST_SUITE` — suite label for filtering / debugging
- `ALLURE_RESULTS_DIR` — path to directory containing Allure `*-result.json` files (e.g. `allure-results`, `target/allure-results`)

### 3. When to upload metrics

- **`full-tests.yml`**: after tests produce `allure-results`, generate and upload (baseline).
- **`nightly.yml`**: same steps after Allure results exist, so **scheduled** runs also feed the dashboard (parity with full-tests).

Use `if: always()` on generate/upload where the repo wants metrics even when tests fail (matches full-tests pattern).

**Matrix / parallel jobs**: a single key `.../${{ github.run_id }}.json` overwrites concurrent matrix legs. Use a **unique object key** per leg, e.g. `${{ github.run_id }}-${{ matrix.suite }}.json` under `qa-portfolio-metrics/<repo>/`. The qa-dashboard aggregator walks subdirectories recursively.

### 4. qa-dashboard pipeline

Repository: **qa-dashboard** (sibling of the five automation repos).

Workflow: [aggregate.yml](https://github.com/dsolisp/qa-dashboard/blob/main/.github/workflows/aggregate.yml) (conceptual path):

1. `aws s3 sync s3://qa-portfolio-metrics/` → local `data/raw/`
2. `node scripts/build-summaries.mjs` — collects all `*.json` with valid `repo` + `run_id`, writes `public/data/summaries.json`
3. `npm run build` (Vite static site)
4. **peaceiris/actions-gh-pages** — publishes `dist/` to `gh-pages` branch

Schedule: daily cron (e.g. `0 6 * * *`) plus `workflow_dispatch`.

### 5. GitHub secrets

**Per automation repo** (full-tests + nightly metrics upload):

- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`
- `R2_ACCOUNT_ID`
- `R2_PUBLIC_URL` (optional; for Allure links in step summary, not required for metrics JSON)

**qa-dashboard** aggregate job:

- Same R2 read credentials for `aws s3 sync` from `qa-portfolio-metrics`
- `GITHUB_TOKEN` (default) for Pages deploy via peaceiris action

**Optional**: Custom DNS (CNAME) for GitHub Pages — configure in repo Settings → Pages; document canonical URL in qa-dashboard README. No change to R2 layout.

---

## Rationale

- Separating **metrics JSON** from **Allure HTML** keeps aggregation fast and cheap.
- One schema across five stacks lets one dashboard job stay dumb: sync + merge JSON.
- Nightly parity ensures the dashboard reflects **scheduled** health, not only manual `full-tests` runs.

---

## Consequences

### Positive

- Single executive URL (GitHub Pages) for portfolio reviewers.
- Historical runs accumulate in R2; dashboard can evolve to show trends without re-scanning Allure.

### Trade-offs

- R2 and GitHub secrets must be maintained for all repos that upload metrics.
- Matrix jobs require disciplined **unique** summary keys to avoid silent overwrites.

---

## Verification (after workflow changes)

1. In any consumer repo, run **`workflow_dispatch`** on **Nightly** (or wait for schedule).
2. In R2 bucket `qa-portfolio-metrics`, confirm a new object under `<repo>/` (Cypress: `<repo>/<run_id>-<suite>.json`).
3. In **qa-dashboard**, run **Aggregate Metrics + Deploy** (`workflow_dispatch`) or wait for cron; confirm `summaries.json` includes the new `run_id` after build.

Locally, `node scripts/build-summaries.mjs` (with `data/raw/` populated from a sample JSON) validates the merge logic without R2.

---

## Appendix: Default public URL (no custom domain)

Unless a custom domain is configured, the dashboard is served from **GitHub Pages** for the `qa-dashboard` repository, typically:

`https://<github-username>.github.io/qa-dashboard/`

Replace `<github-username>` with the account or org that owns the repo (see qa-dashboard README for the canonical link used in this portfolio).
