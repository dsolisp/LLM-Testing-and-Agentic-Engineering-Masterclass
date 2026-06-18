# ADR-015: Hermetic Test Isolation Strategy

**Status**: ✅ Accepted (Phase 12)
**Date**: 2026-05-04
**Deciders**: QA Architecture Team
**Related**: [STANDARDS.md](../../STANDARDS.md), [HERMETIC_TESTING.md](../HERMETIC_TESTING.md)

---

## Context

All five repos contain backend tests that read/write database state. Today, each repo relies on a shared DB artifact (e.g., `app.db`) which creates:

- Flaky tests due to cross-test coupling
- Unsafe parallelization
- Non-reproducible local vs CI outcomes

We want hermetic tests: each test (or test class) should run with isolated DB state.

---

## Decision

We standardize on a 3-tier approach and pick the best tier per repo/test-suite:

| Tier | Strategy | Default scope |
|---|---|---|
| L1 | Transaction per test (`BEGIN` / `ROLLBACK`) | Per test |
| L2 | Fresh DB per test/class (SQLite `:memory:` or temp DB) | Per test or per class |
| L3 | Testcontainers + Postgres | Per class or per suite |

Additionally, we require seeding to be connection-based:

- Seeding must be `seed(connection)` (or equivalent) rather than “delete and rewrite `app.db` on disk”.

---

## Rationale

- **L1** is the fastest baseline for reducing coupling when the DB access is easily routed through one connection.
- **L2** provides strong isolation for SQLite-based stacks with minimal infra.
- **L3** provides production-grade realism and a high-signal portfolio demo in at least one stack (Python).

The `seed(connection)` rule is the enabling constraint for all tiers.

---

## Consequences

### ✅ Positive

- Parallel execution becomes safe by default.
- DB tests become reproducible (local == CI).
- Enables future observability improvements (e.g., trace per test) without hidden shared state.

### ⚠️ Costs / trade-offs

- Some tests must be refactored to accept an injected connection/transaction fixture.
- L3 requires container runtime in CI and extra wiring.

---

## Implementation notes (Phase 12)

- Start with **Python**: convert DB seeding to `seed(conn)` and use a hermetic fixture for backend DB tests.
- Backport L1/L2 patterns to the other stacks as they touch DB validation tests.

