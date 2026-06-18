# ADR-012 — Tooling Decisions Per Stack

## Status
Accepted — 2026-05-02

## Context

Each of the five repos uses language-specific tooling. This ADR documents the **canonical
tooling choices** for each stack and the rationale. Changes to any of these choices require
updating this ADR.

## Decision

### Python repo

| Concern | Tool | Rationale |
|---------|------|-----------|
| Package management | `uv` + `pyproject.toml` | Fastest resolver; single lock file; replaces pip/venv/pip-tools |
| Linting | `ruff` (select ALL) | 10–100× faster than flake8+pylint; single config in pyproject.toml |
| Architecture guardrails | `import-linter` | Enforces import contracts without a test runner |
| Test runner | `pytest` | De facto standard; rich fixture model |
| Assertions | `PyHamcrest` | Expressive matchers; consistent with Java (Hamcrest origin) |
| Test data | `factory_boy` + `Faker` | Fluent builder API; Faker for realistic data |
| Logging | `structlog` | JSON output in CI; pretty output locally |
| A11y | `axe-selenium-python` | Official Deque binding |
| Git hooks | `lefthook` | Polyglot; consistent with other repos |

### TypeScript — Playwright repo

| Concern | Tool | Rationale |
|---------|------|-----------|
| Package management | `pnpm` | Faster installs; strict peer deps; deterministic lockfile |
| Linting | `ESLint` (strict) + custom rules | `no-restricted-syntax` blocks selector leaks |
| Architecture guardrails | `ESLint no-restricted-imports/syntax` | Native ESLint; no extra dependency |
| Test runner | `Playwright Test` | Built-in parallelism; trace viewer; storageState |
| BDD | `playwright-bdd` (Cucumber) | First-class Playwright integration; no workarounds |
| Assertions | `expect` (Playwright built-in) | Retry-aware; designed for async UI |
| Test data | `@faker-js/faker` + builder classes | Type-safe via TS interfaces |
| A11y | `@axe-core/playwright` | Official Deque binding for Playwright |
| Git hooks | `lefthook` | Consistent with other repos |

### TypeScript — Cypress repo

| Concern | Tool | Rationale |
|---------|------|-----------|
| Package management | `pnpm` | Same as Playwright repo for consistency |
| Linting | `ESLint` + `eslint-plugin-cypress` | Cypress-aware rules + custom no-restricted-syntax |
| Test runner | `Cypress` v13+ | Industry-recognized; excellent DX for component + E2E |
| Session reuse | `cy.session()` | Built-in Cypress session caching |
| Test data | `@faker-js/faker` + builder classes | Same pattern as Playwright |
| A11y | `cypress-axe` | Official Deque binding for Cypress |
| Multi-tab | Stub strategy | See ADR-006 |
| Git hooks | `lefthook` | Consistent |

### Java repo

| Concern | Tool | Rationale |
|---------|------|-----------|
| Build | `Maven` | Existing; well-supported in CI |
| Java version | JDK 21 (LTS) | Latest LTS; virtual threads available |
| Test runner | `JUnit 5.11+` | Jupiter; parameterized tests; extensions model |
| Selenium | `4.x` | Native CDP; relative locators; W3C only |
| Assertions | `AssertJ` | Fluent; excellent IDE completion |
| Architecture guardrails | `ArchUnit` | De facto standard for Java architecture tests |
| Test data | `Datafaker` | Faker successor; actively maintained |
| Async waits | `Awaitility` | Fluent condition polling |
| Code format | `Spotless` + `Google Java Format` | Enforced in CI |
| A11y | `selenium-axe-java` | Deque binding |
| Git hooks | `lefthook` | Consistent |

### C# repo

| Concern | Tool | Rationale |
|---------|------|-----------|
| Runtime | `.NET 9` | Latest stable LTS-track release |
| Test runner | `xUnit v3` | Parallel-by-default; modern async support |
| BDD | `Reqnroll` (SpecFlow successor) | Drop-in replacement; actively maintained |
| Selenium | `WebDriver 4.x` | Same as Java |
| Assertions | `FluentAssertions` | Richest .NET assertion library |
| Architecture guardrails | `NetArchTest` | Fluent architecture rules for .NET |
| Test data | `Bogus` | Most popular .NET fake-data library; Faker-compatible API |
| Code format | `dotnet-format` + `.editorconfig` | First-party; no extra deps |
| A11y | `Deque.AxeCore.Selenium` | Official Deque binding |
| Git hooks | `lefthook` | Consistent |

### Cross-stack

| Concern | Tool | Rationale |
|---------|------|-----------|
| Task runner | `Taskfile` (per repo) | Single interface; works with any language |
| Dependency updates | `Renovate` (per repo) | Best auto-merge config; groups by ecosystem |
| Git hooks | `lefthook` | Polyglot; fast; YAML config |
| Commit convention | `Conventional Commits` + `commitlint` | Enables release-please changelog |
| Reports | `Allure` (per repo, own dashboard) | Rich; supports all 5 runners; history trends |

## Consequences

### Positive
- Every tool choice is documented with rationale — reviewers can evaluate decisions, not just observe them.
- Tooling is consistent where it matters (lefthook, Taskfile, Renovate, Allure) and language-idiomatic where it doesn't.

### Negative
- Five separate tool ecosystems require five separate CI setups (by design — each repo is independent).
- Updating a cross-stack tool (e.g., lefthook) requires 5 PRs (mitigated by `sync-standards.sh`).
