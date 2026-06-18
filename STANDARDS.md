# QA Portfolio — Architectural Standards
<!-- SYNC-MANAGED — do not edit in project repos. Edit in shared-docs/ and run sync-standards.sh -->
> **Version:** 1.0.0 · **Status:** Enforced · **Owner:** QA Architect  
> **Scope:** All seven project repos — Python · Playwright · Cypress · Java · C# · API · LLM/Agentic
> **Enforcement:** Per-repo CI (`audit_violations.sh`) + import-linter / ArchUnit / Roslyn / ESLint  

---

## The 7 Laws

These rules are **inviolable**. Every PR must satisfy all 7 before merge.  
CI fails automatically on any violation. Exceptions require a new ADR.

---

### Law 1 — Locator Mirroring 1:1

**Rule:** Every Page Object file must have a corresponding Locator file in the `locators/`
directory (same name, same path structure). Locator files contain **only** selector
definitions — zero logic, zero imports beyond what is needed to declare a selector type.

| ✅ Correct | ❌ Violation |
|-----------|-------------|
| `pages/sauce/login_page.py` ↔ `locators/sauce/login_locators.py` | Selectors declared directly inside `login_page.py` |
| `pages/advanced/DropdownPage.java` ↔ `locators/advanced/DropdownLocators.java` | No corresponding locator file exists |

**Rationale:** Enables global selector refactors in a single file. Provides a machine-readable
inventory of every element under test. Enforced by `audit_violations.sh --check-mirroring`.

**ADR:** [ADR-001](docs/adr/ADR-001-locator-mirroring.md)

---

### Law 2 — Zero Assertions in Pages / Locators

**Rule:** Files under `pages/` and `locators/` (and their stack equivalents) must contain
**zero** assertion statements. Return values; let tests assert.

| ✅ Correct | ❌ Violation |
|-----------|-------------|
| `def get_error_message(self) -> str: return self.driver.find_element(...).text` | `assert "Error" in self.driver.find_element(...).text` inside a page method |
| `getErrorMessage(): Locator { return this.page.locator(...) }` | `expect(this.page.locator(...)).toBeVisible()` inside a page class |

**Banned keywords by stack:**

| Stack | Banned in pages/ & locators/ |
|-------|------------------------------|
| Python | `assert`, `assert_that`, `hamcrest` |
| TypeScript (PW/Cypress) | `expect(`, `.should(`, `cy.contains(` used as assertion |
| Java | `assertThat`, `assertEquals`, `assertTrue` |
| C# | `Assert.`, `.Should()`, `FluentAssertions` |

**ADR:** [ADR-002](docs/adr/ADR-002-no-assertions-in-poms.md)

---

### Law 3 — Zero Selectors in Test Specs

**Rule:** Files under `tests/` (or `e2e/`, `specs/`) must contain **zero** raw selector
expressions. Tests call page/component methods only.

| ✅ Correct | ❌ Violation |
|-----------|-------------|
| `login_page.enter_credentials(user)` | `driver.find_element(By.ID, "user-name").send_keys(user)` in a test |
| `loginPage.fillCredentials(user)` | `cy.get('[data-test="username"]').type(user)` in a spec file |

**Banned patterns by stack:**

| Stack | Banned in tests/ |
|-------|-----------------|
| Python | `By.`, `find_element`, `find_elements` |
| TypeScript (PW) | `page.locator(`, `page.getBy` |
| TypeScript (Cypress) | `cy.get(`, `cy.find(` |
| Java | `By.`, `driver.findElement` |
| C# | `By.`, `driver.FindElement` |

**ADR:** [ADR-003](docs/adr/ADR-003-no-selectors-in-specs.md)

---

### Law 4 — Inheritance ≤ 1 Level (Composition Over Inheritance)

**Rule:** Page objects may extend at most **one** base class (`BasePage`). No chains like
`CheckoutPage → SaucePage → BasePage`. Shared behavior lives in mixins, helpers, or
components — composed via injection, not inheritance.

| ✅ Correct | ❌ Violation |
|-----------|-------------|
| `class LoginPage(BasePage)` with `WaitMixin` composed | `class LoginPage(SaucePage)` where `SaucePage(BasePage)` |
| `class DropdownPage extends BasePage` using `WaitHelpers` helper class | `class DropdownPage extends AdvancedPage extends BasePage` |

**ADR:** [ADR-004](docs/adr/ADR-004-composition-over-inheritance.md)

---

### Law 5 — Stateless Page Objects

**Rule:** Page Object instances must hold **no mutable state** beyond `driver/page` and the
injected `locators` reference. No caching of DOM elements between method calls.
No instance variables set during test execution.

| ✅ Correct | ❌ Violation |
|-----------|-------------|
| `def get_product_names(self): return [e.text for e in self.driver.find_elements(...)]` | `self.product_names = [...]` cached as instance field |
| Each test instantiates a fresh page object | Singleton page object shared across tests |

**Rationale:** Stateless POMs are safe to run in parallel and produce no cross-test pollution.

**ADR:** [ADR-002](docs/adr/ADR-002-no-assertions-in-poms.md)

---

### Law 6 — Pure Stateless Utilities

**Rule:** All helpers under `utils/` must be **pure functions or stateless classes** — no
shared state, no singletons (except driver factories), no side effects beyond I/O and logging.

| ✅ Correct | ❌ Violation |
|-----------|-------------|
| `def format_price(value: float) -> str` (pure function) | `Utils.cached_driver` mutable class-level attribute |
| `class CheckoutBuilder` that returns a new immutable object each call | `class TestState` with global mutable dicts |

**ADR:** [ADR-008](docs/adr/ADR-008-test-data-builders.md)

---

### Law 7 — Identical Naming Across Stacks

**Rule:** The class name, file name, and method names for equivalent pages and components must
be **identical across all 5 repos** (adjusting only for language casing conventions).

| Python | Java | C# | TypeScript |
|--------|------|----|------------|
| `LoginPage` | `LoginPage` | `LoginPage` | `LoginPage` |
| `login_page.py` | `LoginPage.java` | `LoginPage.cs` | `login.page.ts` |
| `enter_credentials()` | `enterCredentials()` | `EnterCredentials()` | `enterCredentials()` |
| `DropdownLocators` | `DropdownLocators` | `DropdownLocators` | `DropdownLocators` |

**Rationale:** Makes documentation, code reviews, and recruiter comparisons frictionless.
Enforced by `audit_violations.sh --check-naming` against the canonical mapping in
[TEST_PARITY.md](../TEST_PARITY.md).

**ADR:** [ADR-007](docs/adr/ADR-007-test-parity-policy.md)

---

## Enforcement Matrix

| Law | Python | TypeScript (PW/Cy) | Java | C# |
|-----|--------|--------------------|------|----|
| 1 — Locator Mirroring | `audit_violations.sh` | `audit_violations.sh` | `audit_violations.sh` | `audit_violations.sh` |
| 2 — No assertions in POMs | `import-linter` + `ruff` | `ESLint no-restricted-*` | `ArchUnit` | `Roslyn / NetArchTest` |
| 3 — No selectors in specs | `import-linter` + `ruff` | `ESLint no-restricted-*` | `ArchUnit` | `Roslyn / NetArchTest` |
| 4 — Inheritance ≤ 1 | `import-linter` | `ESLint` | `ArchUnit` | `NetArchTest` |
| 5 — Stateless POMs | Code review + `ruff` | Code review + `ESLint` | Code review + `ArchUnit` | Code review |
| 6 — Pure utils | `ruff` + `import-linter` | `ESLint` | `ArchUnit` | `NetArchTest` |
| 7 — Identical naming | `audit_violations.sh` | `audit_violations.sh` | `audit_violations.sh` | `audit_violations.sh` |

---

## Violation Handling

1. **CI fails** — the PR cannot be merged.
2. Author **must fix** the violation (not suppress the lint rule).
3. Exceptions require a new **ADR** approved by the QA Architect before the rule can be
   relaxed for a specific case.
4. Repeat violators must review the relevant ADR before the next PR.

---

*Canonical source: `/Personal/shared-docs/STANDARDS.md`*  
*Synced to each repo via `scripts/sync-standards.sh` — See [ADR-013](docs/adr/ADR-013-multirepo-sync-strategy.md)*
