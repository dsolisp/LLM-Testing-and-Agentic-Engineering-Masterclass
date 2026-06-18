# ADR-007 — Test Parity Policy

## Status
Accepted — 2026-05-02

## Context

Five independent repos implementing the same application scenarios will naturally drift if
there is no enforced contract. Without parity enforcement:

- Some stacks would have tests that others lack, making cross-stack comparison misleading.
- Recruiting reviewers inspecting two stacks would see different feature coverage.
- CI in one repo going red might be caused by a scenario that simply doesn't exist in
  another repo, hiding the actual coverage gap.

## Decision

### Canonical test inventory

The exact set of 45 canonical test scenarios is defined in `TEST_PARITY.md` at the root of
each repo (synced from `shared-docs/`). Each scenario has:

- A unique **canonical ID** (e.g., `SAUCE-01`, `ADV-E1`, `API-01`, `DB-01`, `A11Y-01`, `VIS-01`).
- A human-readable **scenario name**.
- The **expected outcome**.
- The **exact test function/method name** in each of the 5 stacks.

### Suite breakdown (45 total)

| Suite | Count | IDs | Target URL |
|-------|-------|-----|------------|
| SauceDemo Web (E2E) | 12 | SAUCE-01…12 | https://www.saucedemo.com |
| Advanced Interactions | 9 | ADV-E1…E9 | PRACTICE_BASE_URL |
| API | 8 | API-01…08 | https://reqres.in or JSONPlaceholder |
| Database | 6 | DB-01…06 | Local SQLite |
| Accessibility | 5 | A11Y-01…05 | https://www.saucedemo.com |
| Visual | 5 | VIS-01…05 | https://www.saucedemo.com |

### Parity enforcement mechanism

**Per-repo (runs in CI):** `scripts/check-parity.sh` parses the test files of that repo,
extracts canonical IDs from tags/markers, and fails the build if any canonical ID from
`TEST_PARITY.md` is missing.

**Cross-repo (runs locally):** `Personal/scripts/check_parity.py` iterates all 5 repos
and produces a consolidated parity matrix (JSON + Markdown table).

### Naming convention

| Stack | Convention | Example |
|-------|------------|---------|
| Python | `snake_case` | `test_login_with_valid_credentials` |
| TypeScript | `camelCase` description | `"logs in with valid credentials"` |
| Java | `camelCase` method | `loginWithValidCredentials()` |
| C# | `PascalCase` method | `LoginWithValidCredentials()` |

The canonical ID is applied as a marker/tag in each stack:
`@pytest.mark.sauce_01` · `test.info().annotations` · `@Tag("SAUCE-01")` · `[Trait("id", "SAUCE-01")]`

### Exception process

Adding a new scenario to ANY stack requires adding it to `TEST_PARITY.md` AND implementing
it in all 5 stacks within the same PR. Exceptions (e.g., stack-specific capability, ADR-006
Cypress limitation) must reference the relevant ADR in both `TEST_PARITY.md` and the test.

## Consequences

### Positive
- Every stack always has the same 45 scenarios — cross-stack comparison is always apples-to-apples.
- Parity gaps surface immediately in CI — no silent drift.

### Negative
- Adding a new scenario requires touching all 5 repos (by design — it enforces discipline).
- Stack-specific constraints (like ADR-006) require documentation, not avoidance.
