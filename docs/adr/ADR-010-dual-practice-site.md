# ADR-010 — Dual Practice Site Strategy (Local + Heroku Fallback)

## Status
Accepted — 2026-05-02

## Context

The Advanced Interactions suite (ADV-E1 through E9) tests UI patterns such as dropdowns,
iframes, new-tab navigation, and JS alerts. These scenarios require a stable, deterministic
web application — the same target for all 5 stacks.

**The Internet** (https://the-internet.herokuapp.com) is a well-known practice site covering
all required patterns. However:

- It is a **publicly hosted, shared resource** — subject to downtime, Heroku free-tier
  cold-start latency (10–30s first request), and potential content changes.
- Its `/dropdown` route does not have a dynamic-loading variant (needed for ADV-E2).
- CI pipelines that depend on an external URL introduce flakiness outside the team's control.

## Decision

Use a **dual-target strategy** controlled by the `PRACTICE_BASE_URL` environment variable:

| Environment | Value | Notes |
|-------------|-------|-------|
| Local development (default) | `http://localhost:8080` | `qa-practice-app/` at monorepo root, via Docker |
| CI (primary) | `http://localhost:8080` | Started via `docker compose up -d` in CI step |
| CI (fallback / smoke) | `https://the-internet.herokuapp.com` | Used only if Docker is unavailable |
| Manual | any URL | Developer can point to any compatible host |

### `qa-practice-app/` specification

A **Dockerized nginx-alpine application** in the top-level `qa-practice-app/` folder (sibling to the stack repos in the Personal workspace). Intended to be **extractable into its own Git repository**; stacks only need `PRACTICE_BASE_URL` pointing at wherever it runs.

| Route | Scenario covered | Notes |
|-------|-----------------|-------|
| `/` | Landing page | Links to all 4 demo routes |
| `/dropdown.html` | ADV-E1, ADV-E2 | Static select + dynamic select (1.5s fetch delay) |
| `/iframes.html` | ADV-E3, ADV-E4 | Outer + nested iframes |
| `/windows.html` + `/windows/new` | ADV-E5, ADV-E6 | `target=_blank` + `window.open()` |
| `/alerts.html` | ADV-E7, ADV-E8, ADV-E9 | alert / confirm / prompt |

All routes use `data-test` attributes as the canonical selector strategy.
Image size budget: < 25 MB.

### Stack configuration

Each stack reads `PRACTICE_BASE_URL` from environment (defaulting to `http://localhost:8080`):

```python
# Python
BASE_URL = os.getenv("PRACTICE_BASE_URL", "http://localhost:8080")
```

```typescript
// TypeScript
const BASE_URL = process.env.PRACTICE_BASE_URL ?? "http://localhost:8080";
```

```java
// Java
String BASE_URL = System.getenv().getOrDefault("PRACTICE_BASE_URL", "http://localhost:8080");
```

```csharp
// C#
var BASE_URL = Environment.GetEnvironmentVariable("PRACTICE_BASE_URL") ?? "http://localhost:8080";
```

### Route compatibility

`qa-practice-app/` routes are designed to match the Heroku equivalents:

| Local route | Heroku equivalent |
|-----------------------|-------------------|
| `/dropdown.html` | `/dropdown` |
| `/iframes.html` | `/iframe` + `/nested_frames` |
| `/windows.html` | `/windows` |
| `/alerts.html` | `/javascript_alerts` |

## Consequences

### Positive
- Tests run fully offline — no external dependency in normal CI runs.
- The dynamic dropdown variant (E2) is only possible with the local app.
- `data-test` attributes provide stable selectors not subject to Heroku content changes.
- Heroku fallback available for quick smoke tests without Docker.

### Negative
- `qa-practice-app/` must be kept in sync with the test expectations (small maintenance cost).
- Docker must be available in CI runners (standard in GitHub Actions — no extra cost).
