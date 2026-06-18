# ADR-013 — Multi-Repo Sync Strategy

## Status
Accepted — 2026-05-02

## Context

The QA portfolio consists of five **independent** git repositories (Python · Playwright ·
Cypress · Java · C#) that share a common set of cross-cutting artifacts:

- Architectural standards (`STANDARDS.md`)
- Architectural Decision Records (`docs/adr/`)
- Lint configurations (ruff, ESLint, checkstyle, dotnet-format)
- CI workflow templates (`.github/workflows/test.yml`, `allure-publish.yml`)
- Git hooks template (`lefthook.yml`)
- Dependency-update config (`renovate.json`)
- PR / issue templates (`.github/`)
- Audit scripts (`scripts/audit_violations.sh`, `scripts/check-sync.sh`)

These five repositories live side-by-side under a **local workspace organizer**
(`/Personal/`) that is **NOT a published git repository** and is **NOT deployed anywhere**.
There is no central monorepo — each project repo is fully independent and self-contained.

**Challenge:** keep shared artifacts consistent across the 5 repos without git submodules,
without a dedicated published shared-docs repo, and without manual drift.

## Decision

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | **Canonical source of truth** = `/Personal/shared-docs/` — a plain local folder, not a git repo | Zero extra repos; accessible instantly from the workspace |
| 2 | **Propagation** via `scripts/sync-standards.sh` — copies files + generates SHA-256 manifest | Developer controls when to sync; no hidden automation |
| 3 | **Drift detection** — `manifest.sha256` committed in every target repo; CI runs `scripts/check-sync.sh` and fails if checksums diverge | Catches accidental in-repo edits of synced files before merge |
| 4 | **Update workflow** — edit in `shared-docs/` → run `sync-standards.sh` → review diff in each repo → commit + push | Single mental model: shared-docs is always the source |

### Files managed by sync (never edit directly in project repos)

```
STANDARDS.md
docs/adr/ADR-001 … ADR-013.md
lefthook.yml                    (stack-specific sections added post-sync)
renovate.json                   (ecosystem field set per repo post-sync)
.github/PULL_REQUEST_TEMPLATE.md
.github/ISSUE_TEMPLATE/
.github/workflows/test.yml      (runtime steps adapted post-sync)
.github/workflows/allure-publish.yml
scripts/audit_violations.sh
scripts/check-sync.sh
manifest.sha256
```

### Files NOT managed by sync (repo-specific, never overwritten)

```
Taskfile.yml          (stack-specific commands)
commitlint.config.js  (same content but owned per repo)
CONTRIBUTING.md       (common base + stack-specific section)
README.md             (common template + stack-specific content)
```

## Consequences

### Positive
- Zero additional repos or git submodules required.
- Each project repo stays fully self-contained and independently publishable.
- Drift caught automatically on every CI run (no silent divergence).
- Rollback is trivial: revert the commit in the affected repo.

### Negative
- Sync is a **manual developer action** (must remember to run the script).
- `shared-docs/` exists only on the developer's local machine — no remote backup.
  Mitigated: every synced file has a committed copy in each of the 5 published repos,
  so the canonical can be reconstructed from any one of them at any time.
- Direct edits to synced files inside a project repo will fail CI until resolved.
  This is intentional — it forces the developer back to the correct workflow.
