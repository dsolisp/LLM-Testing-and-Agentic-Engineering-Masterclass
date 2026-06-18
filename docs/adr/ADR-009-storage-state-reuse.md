# ADR-009 — Storage State / Session Reuse for Authentication

## Status
Accepted — 2026-05-02

## Context

Every SauceDemo test that requires an authenticated session performed a full UI login sequence
at the start of the test or suite. Measured cost per login: ≈ 3–5 seconds (driver startup +
page load + credentials fill + redirect).

With 12 SauceDemo + 5 A11y + 5 Visual tests = 22 tests requiring auth, login overhead was:
**22 × 4s ≈ 88 seconds** per run, per stack.

Additionally, repeated UI logins introduced a source of flakiness (network latency, occasional
CAPTCHA-like bot detection on CI runners).

## Decision

Implement session reuse (storage state) in all 5 stacks: **log in once per suite**, persist
the session (cookies + localStorage), and re-inject it for subsequent tests.

### Per-stack mechanism

| Stack | Mechanism | Storage location |
|-------|-----------|-----------------|
| Python (Selenium) | `authenticated_driver` session-scoped fixture; dumps cookies via `driver.get_cookies()` to `.auth/sauce.json`; re-injects with `driver.add_cookie()` | `.auth/sauce.json` |
| Java (Selenium) | `CookieStore` JUnit 5 extension; `@BeforeAll` logs in; `@BeforeEach` injects cookies | `.auth/sauce.json` |
| C# (Selenium) | `AuthFixture : IClassFixture<AuthFixture>`; `OneTimeSetUp` logs in; `SetUp` injects cookies | `.auth/sauce.json` |
| Playwright | `globalSetup.ts` logs in and saves `.auth/sauce.json`; `playwright.config.ts` sets `storageState` per project | `.auth/sauce.json` |
| Cypress | `cy.session('sauce-standard', loginViaUI)` in `beforeEach`; Cypress caches session state internally | Cypress session cache |

### Opt-out flag

Each stack provides a way to force a fresh login (useful for debugging auth state):

| Stack | Opt-out |
|-------|---------|
| Python | `pytest --no-cache-auth` |
| Java | `-Dno.cache.auth=true` |
| C# | `NO_CACHE_AUTH=true` env var |
| Playwright | `PLAYWRIGHT_FRESH_AUTH=true` env var |
| Cypress | `cy.session` disabled via `Cypress.config` flag |

### Security note

`.auth/sauce.json` is listed in `.gitignore` in all repos. It is never committed.
In CI, the file is generated during `globalSetup` / `beforeAll` and exists only for the
duration of that workflow run.

### Expected impact

| Metric | Before | After |
|--------|--------|-------|
| Login actions per run | 22 | 1 |
| Estimated time saving | — | ≈ 80s per stack |
| Flakiness source (login) | Present | Eliminated |

## Consequences

### Positive
- Dramatic reduction in test wall-clock time (~60–80% for auth-dependent suites).
- Eliminates login as a flakiness source.
- Session state is transparent — `.auth/sauce.json` can be inspected for debugging.

### Negative
- If the application rotates session cookies, the cached state may become invalid
  mid-run. Mitigated by the opt-out flag and by a session-validity check in the fixture.
- Tests that specifically validate the login flow (SAUCE-01 — login page) must explicitly
  NOT use the cached session. These tests clear auth state before running.
