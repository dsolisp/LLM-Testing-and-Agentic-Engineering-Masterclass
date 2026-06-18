# ADR-013: Structural Parity & 1:1 Mirroring Across Test Stacks

**Status**: ✅ Accepted  
**Date**: 2026-05-03  
**Deciders**: QA Architecture Team  
**Related**: [ADR-001](./ADR-001-gold-standard-architecture.md), [STANDARDS.md](../../STANDARDS.md) (Law 1: 1:1 Mirroring)

---

## Context

After Phase 5b (bringing Cypress, Playwright, and Python to feature parity), a macro-level inconsistency was identified:

| Concern | Cypress | Playwright (before) | Python (before) |
|---|---|---|---|
| **UI tests** | `cypress/e2e/ui/` | `tests/e2e/` | `tests/web/` |
| **Visual tests** | `ui/visual/` | `e2e/visual/` | ❌ missing |
| **API tests** | `api/` | `e2e/api/` | `api/` |
| **Database tests** | `api/database.cy.ts` | `database/database.test.ts` | ❌ missing |
| **Accessibility** | ❌ missing (stub) | `e2e/accessibility/` | `accessibility/` + `web/test_accessibility.py` (duplicate) |

**Problem**: Three different directory naming schemes (`ui/`, `e2e/`, `web/`) for the same conceptual layer violated **Law 1: 1:1 Mirroring** at the structural level. Developers switching between stacks had to mentally map different folder hierarchies.

---

## Decision

Enforce a **unified canonical directory structure** across all test stacks (Cypress, Playwright, Python, Java):

```
<root>/                 # cypress/ (Cypress) OR tests/ (Playwright, Python)
├── ui/
│   ├── practice/       # QA Practice App (http://localhost:8080)
│   ├── sauce/          # SauceDemo tests
│   └── visual/         # Visual regression (UI concern)
├── api/
│   ├── api.<ext>       # REST API tests
│   ├── contract.<ext>  # Contract tests
│   └── database.<ext>  # Database query validation
├── accessibility/
│   ├── accessibility.<ext>
│   └── lighthouse.<ext>
├── performance/
│   └── performance.<ext> (+ locustfile.py for Python)
├── integration/
│   ├── e2e-flow.<ext>
│   └── framework-integration.<ext>
├── unit/               # Unit tests (Playwright + Python only)
├── bdd/                # Cucumber BDD (Playwright only)
└── auth/               # Auth setup (Playwright only — `projects: setup` pattern)
```

**Note**: Root naming varies by framework convention:
- **Cypress**: `cypress/` (enforced by Cypress)
- **Playwright**: `tests/` (industry standard)
- **Python**: `tests/` (industry standard)
- **Java**: `src/test/java/com/automation/` (Maven Standard Directory Layout)

The subdirectory structure beneath the root is **identical** across all four stacks.

**File naming conventions** (framework-mandated):
- **Cypress**: `<name>.cy.ts`
- **Playwright**: `<name>.spec.ts`
- **Python**: `test_<name>.py`

---

## Rationale

### Why `ui/` instead of `e2e/` or `web/`?
- **Cypress** already used `ui/` (the reference stack for Phase 5b).
- **`e2e/`** is ambiguous — API and database tests are also end-to-end.
- **`web/`** conflates Selenium (the tool) with UI (the concern).
- **`ui/`** is semantically clear and maps 1:1 to Playwright's `@web` and Python's `@ui` markers.

### Why `visual/` under `ui/`?
- Visual regression is a **UI concern** — it validates rendered pixels, not API responses or database state.
- Mirrors Cypress's existing structure (`ui/visual/`).

### Why `database` under `api/`?
- Database validation is a **backend/data concern**, not a UI or integration test.
- Cypress already placed `database.cy.ts` under `api/`.
- Playwright's standalone `database/` folder created artificial separation.

### Tooling-specific directories
- **`bdd/`**: Only Playwright has Cucumber integration (`playwright-bdd`). Cypress and Python lack equivalent first-class support.
- **`auth/`**: Playwright's `projects: setup` pattern (e.g., `sauce.setup.ts`) requires a dedicated folder to match its `testMatch` glob. Cypress uses `cy.session()` in support files; Python uses fixtures in `conftest.py`.
- **`unit/`**: Vitest (Playwright) and pytest (Python) both support unit testing. Cypress does not.

### Intentional gaps (Cypress)
Cypress lacks native support for:
- **Accessibility**: No equivalent to `@axe-core/playwright` or `axe-selenium-python`. Stub file created for structural parity with `it.skip()`.
- **Performance**: No built-in web vitals or Lighthouse integration. Stub file created.
- **Integration**: No existing multi-phase e2e flow tests. Stub file created with TODO to port from Playwright.

These gaps are **documented, not violations** — the stubs enforce 1:1 Mirroring at the directory level while acknowledging tooling constraints (see ADR-012).

---

## Consequences

### ✅ Positive
1. **Cognitive load reduced**: Switching between Cypress, Playwright, Python, and Java no longer requires mental mapping of different folder schemes.
2. **Law 1 compliance**: 1:1 Mirroring now applies at both the **micro level** (page objects, locators) and the **macro level** (directory structure).
3. **Discoverability**: `git ls-files | grep ui/practice/` returns equivalent files in all stacks.
4. **CI/CD simplification**: Future multi-stack test runners can assume uniform subdirectory paths (e.g., `ui/`, `api/` after root).

### ⚠️ Breaking Changes
1. **Config updates required**:
   - `playwright.config.ts`: `testMatch` globs updated.
   - `package.json` scripts: All `test:*` scripts updated (Playwright + Cypress).
   - `.dependency-cruiser.cjs`: Globs updated to new paths.
2. **Test discovery**: Existing CI workflows relying on old paths (e.g., `tests/e2e/`) must be updated.
3. **Snapshot baselines**: Playwright's `visual-regression.spec.ts-snapshots/` folder renamed to match new spec filename (Playwright couples snapshot dirs to spec names).

### 🔧 Maintenance
- **New test categories**: Future test types (e.g., `tests/security/`, `tests/smoke/`) must be added to **all three stacks** (even if stubbed) to maintain parity.
- **ADR updates**: This ADR supersedes any prior implicit directory conventions.

---

## Implementation Summary (Phase 6)

### Moves Performed
| Stack | Moved Files | New Files | Deleted Files |
|---|---|---|---|
| **Cypress** | 13 (`cypress/e2e/*` → `cypress/*` directly) | 4 (accessibility, performance, integration stubs + schema-validation.cy.ts) | 1 empty dir (`e2e/`) |
| **Playwright** | 15 (all `e2e/*` → `ui/`, `api/`, etc.) | 0 | 10 empty dirs |
| **Python** | 7 (`web/*` → `ui/*`) | 2 (visual, database) | 1 duplicate (`web/test_accessibility.py`) |

### Quality Gates (Post-Refactor)
| Stack | Typecheck | Lint | Depcruise | Status |
|---|---|---|---|---|
| **Cypress** | ✅ Pass | ✅ Pass | N/A | ✅ |
| **Playwright** | ✅ Pass | ✅ Pass (1 pre-existing warning) | ✅ Pass (58 modules, 119 deps) | ✅ |
| **Python** | N/A | ✅ Pass (`ruff check .`) | N/A | ✅ |

---

## References
- [STANDARDS.md — Law 1: 1:1 Mirroring](../../STANDARDS.md#law-1-11-mirroring)
- [ADR-001 — Gold Standard Architecture](./ADR-001-gold-standard-architecture.md)
- [ADR-012 — Tooling Constraints Per Stack](./ADR-012-tooling-per-stack.md)

---

**Next Steps**:
1. Update `.github/workflows/` CI paths to reference new structure.
2. Run full test suite (Cypress, Playwright, Python) to validate end-to-end flows still pass.
3. Update onboarding docs to reference new canonical paths.

---

## Final Directory Comparison (Post-Refactor)

**Before**: Cypress used `cypress/e2e/ui/`, Playwright used `tests/e2e/`, Python used `tests/web/`
**After**: All stacks use identical subdirectory names after their root

```
Cypress:    cypress/ui/practice/alerts.cy.ts
Playwright: tests/ui/practice/alerts.spec.ts
Python:     tests/ui/practice/test_alerts.py
            ^^^^^^^^^^^^^^^^^ (identical subdirectory structure)
```

**Root Naming Convention**:
- **Cypress**: `cypress/` (framework-enforced convention)
- **Playwright**: `tests/` (industry standard)
- **Python**: `tests/` (industry standard)
- **Java**: `src/test/java/com/automation/` (Maven Standard Directory Layout)

✅ **Result**: Full 1:1 mirroring at the subdirectory level across all four stacks.
