# ADR-014: Backend Consolidation (Renaming api/ to backend/)

**Status**: ✅ Accepted
**Date**: 2026-05-03
**Deciders**: QA Architecture Team
**Related**: [ADR-013](./ADR-013-structural-parity.md), [STANDARDS.md](../../STANDARDS.md)

---

## Context

In ADR-013, we established a 1:1 mirroring directory structure across all stacks, using `api/` to group REST API tests (`api.*`), contract tests (`contract.*`), and database queries (`database.*`).

However, as the project evolved into Phase 8, it became clear that naming this directory `api/` is semantically limiting. Database validations and contract verifications represent broader "backend" concepts, not strictly API interactions. Grouping database and contract tests under an `api/` folder creates confusion and inaccurate taxonomy.

---

## Decision

We will supersede the directory naming rule from ADR-013 regarding `api/`. The directory `api/` will be renamed to `backend/` across all five project stacks (Cypress, Playwright, Python, Java, C#).

The new canonical structure for backend concerns will be:
```text
<root>/
├── backend/
│   ├── api.<ext>       # REST API tests
│   ├── contract.<ext>  # Contract tests
│   └── database.<ext>  # Database query validation
```

---

## Rationale

1. **Semantic Accuracy**: "Backend" accurately encompasses API interactions, database querying, and contract testing, whereas "API" strictly refers to interfaces.
2. **Future Proofing**: If we introduce messaging queues (e.g., Kafka, RabbitMQ) or other backend-specific layers, they logically fit into `backend/` but not necessarily `api/`.
3. **Consistency**: Aligns our automated test boundaries with industry-standard architectural boundaries (Frontend/UI vs. Backend/Services/Data).

---

## Consequences

### ✅ Positive
1. More accurate mental model for developers switching between UI and Backend test layers.
2. Future backend integrations (message brokers, caches, background jobs) have a clear home.

### ⚠️ Breaking Changes
1. All `api/` folders must be renamed to `backend/`.
2. CI/CD test execution scripts, framework configurations (`cypress.config.ts`, `playwright.config.ts`, `pytest.ini`, etc.), and package scripts must be updated to target `backend/` instead of `api/`.
3. Any documentation referencing `api/` tests must be updated.

---

## Implementation Summary (Phase 8)

The rename involves moving the files from `<root>/api/` to `<root>/backend/` in:
- `CypressProject/cypress/`
- `PlaywrightProject/tests/`
- `PythonSeleniumProject/tests/`
- `JavaSeleniumProject/src/test/java/com/automation/`
- `CSharpSeleniumProject/tests/`

All corresponding configuration files and namespaces/packages will be updated to reflect the `backend/` convention.
