# ADR-001 — Locator Mirroring 1:1

## Status
Accepted — 2026-05-02

## Context

Early versions of the portfolio placed CSS/XPath selectors directly inside Page Object
methods. This caused three pain points:

1. **Refactor cost** — a single element rename required hunting selectors across every method
   that touched that element, often across multiple pages.
2. **No inventory** — there was no machine-readable list of every element under test; coverage
   gaps were invisible.
3. **Inconsistency** — different pages used different selector strategies for the same element
   type (sometimes `ID`, sometimes `CSS`, sometimes `XPath`) with no enforced convention.

## Decision

Every Page Object file has a **corresponding Locator file** in a parallel `locators/`
directory, mirroring the exact same path structure.

### Structure (per stack)

| Stack | Page file | Locator file |
|-------|-----------|--------------|
| Python | `pages/sauce/login_page.py` | `locators/sauce/login_locators.py` |
| Java | `pages/sauce/LoginPage.java` | `locators/sauce/LoginLocators.java` |
| C# | `Pages/SauceDemo/LoginPage.cs` | `Locators/SauceDemo/LoginLocators.cs` |
| Playwright | `pages/sauce-demo/login.page.ts` | `locators/sauce-demo/login.locators.ts` |
| Cypress | `pages/sauce-demo/login.page.ts` | `locators/sauce-demo/login.locators.ts` |

### Locator file rules

- Contains **only** selector declarations (tuples, constants, or simple classes).
- Zero logic — no methods beyond a constructor if needed to accept a base URL.
- Zero imports beyond selector-type libraries (`selenium.webdriver.common.by.By`, etc.).
- Maximum **30–50 LOC** per file.

### Page Object rules

- Receives its locator file via **constructor injection** (not instantiated internally).
- Never declares a selector literal — it always references `self.locators.USERNAME_INPUT`.

## Consequences

### Positive
- A global element rename is a one-line change in the locator file.
- `audit_violations.sh --check-mirroring` can verify 1:1 coverage automatically.
- Locator files serve as living documentation of every tested element.

### Negative
- Two files must be created per new page (minor overhead).
- Developers must remember to add new selectors to the locator file rather than inline them.
  Enforced by ESLint / ruff / ArchUnit / Roslyn rules in CI.
