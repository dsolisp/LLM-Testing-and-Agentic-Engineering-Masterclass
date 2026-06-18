# ADR-002 — No Assertions in Page Objects or Locators

## Status
Accepted — 2026-05-02

## Context

Several Page Objects in the portfolio contained assertion statements mixed with navigation
and interaction logic. Examples found during the audit:

- `PlaywrightProject/pages/sauce-demo/login.page.ts` — 10 `expect()` calls inside page methods.
- `CypressProject/cypress/pages/LoginPage.ts` — `.should()` chained inside page helper methods.
- `PythonSeleniumProject/pages/sauce.py` — `assert` statements verifying post-action state.

This violated Separation of Concerns (SoC) in three ways:

1. **Tests lost ownership of assertions** — a failing assertion inside a page method produced
   a confusing stack trace pointing to the page, not the test.
2. **Page reuse was blocked** — a page method that asserted `"success"` could not be reused
   by a test that expected failure.
3. **Multiple responsibilities** — the page both acted on the UI and validated the outcome.

## Decision

Files under `pages/`, `locators/`, and `components/` directories (all stacks) must contain
**zero assertion statements**. Page methods must:

1. **Perform an action** (`click`, `fill`, `select`, `navigate`) OR
2. **Return a value** (`get_error_message() -> str`, `getTitle(): string`) that the test
   then asserts against.

### Banned patterns by stack

| Stack | Banned in pages/ & locators/ |
|-------|------------------------------|
| Python | `assert`, `assert_that(...)`, any hamcrest matcher |
| TypeScript (Playwright) | `expect(...)`, `toBeVisible()`, `toHaveText()` |
| TypeScript (Cypress) | `.should(...)`, `expect(...)`, `cy.contains(...).should(...)` |
| Java | `assertThat(...)`, `assertEquals(...)`, `assertTrue(...)` |
| C# | `Assert.*`, `.Should()`, `FluentAssertions` in any form |

### Compliant pattern

```python
# pages/sauce/login_page.py — CORRECT
def get_error_message(self) -> str:
    return self.driver.find_element(*self.locators.ERROR_MESSAGE).text

# tests/web/test_sauce.py — assertion belongs here
def test_invalid_login_shows_error(login_page):
    login_page.login("invalid_user", "wrong_pass")
    assert_that(login_page.get_error_message(), contains_string("Username and password do not match"))
```

## Consequences

### Positive
- Stack traces point to the test, not the page — failures are immediately actionable.
- Page methods are reusable across positive and negative test scenarios.
- Assertion logic is consolidated in one place, making test intent readable at a glance.

### Negative
- Page methods must be designed to return meaningful values instead of asserting silently.
  This requires slightly more deliberate API design per page.
- Existing pages with embedded assertions must be refactored (tracked in Phase 3, 7, 8).
