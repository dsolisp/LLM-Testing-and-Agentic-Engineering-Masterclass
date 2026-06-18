# ADR-017: Consumer-Driven Contract Testing Scope (historical)

**Status**: ⚠️ Superseded (2026-05-05)
**Date**: 2026-05-04 (accepted); **Superseded**: 2026-05-05
**Deciders**: QA Architecture Team
**Related**: [ADR-016](./ADR-016-distributed-tracing-in-test-execution.md), [STANDARDS.md](../../STANDARDS.md)

---

## Context (original)

Across the five-stack QA ecosystem, we previously used the term “contract tests” for tests that validate **schemas** against real public APIs. That is not consumer-driven contract testing (CDC).

An earlier decision adopted **Pact** (consumer tests + optional PactFlow publish) across all five repos for portfolio parity.

---

## Superseding decision (current)

**Pact and PactFlow are removed** from PythonSeleniumProject, JavaSeleniumProject, PlaywrightProject, CypressProject, and CSharpSeleniumProject.

**Rationale:**

- The portfolio does not own a provider service; broker workflows added complexity without proportional value.
- Schema-focused checks remain as **schema validation** suites (renamed from `test_contract.*`), which is the accurate label for those tests.

---

## Consequences

- CI no longer runs Pact consumer tests or publishes contracts.
- **ADR-017** is retained as history; the active rule is: use **schema validation** naming for JSON/schema checks; do not label them CDC unless a real broker-backed CDC workflow exists.
