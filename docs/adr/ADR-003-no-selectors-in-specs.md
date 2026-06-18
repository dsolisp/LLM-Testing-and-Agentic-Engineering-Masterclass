# ADR-003 — No Selector Literals in Test Specs

## Status
Accepted — 2026-05-02

## Context

Test spec files in the portfolio contained raw selector expressions alongside test logic.
Examples found during the audit:

- `CypressProject/cypress/e2e/` — `cy.get('[data-test="username"]')` used directly in spec.
- `CSharpSeleniumProject/tests/` — `driver.FindElement(By.Id("user-name"))` in test methods.
- `PlaywrightProject/tests/bdd/steps/checkout.steps.ts` — `page.getByTestId(...)` inline in steps.

This violated the "tests narrate intent, not DOM" principle:

1. **Selector coupling** — a DOM change required updating both the page object AND every test
   that referenced the selector directly.
2. **Readability** — test files mixed business language (`"user logs in"`) with technical detail
   (`By.cssSelector(".btn_action")`), making them hard to review with non-technical stakeholders.
3. **Duplication** — the same selector appeared in multiple test files, causing maintenance debt.

## Decision

Files under `tests/`, `e2e/`, `specs/`, or BDD step definitions must contain **zero** raw
selector expressions. Tests interact with the application exclusively through **Page Object**
and **Component Object** method calls.

### Banned patterns by stack

| Stack | Banned in tests/ |
|-------|-----------------|
| Python | `By.ID`, `By.CSS_SELECTOR`, `find_element(...)`, `find_elements(...)` |
| Playwright (TS) | `page.locator(...)`, `page.getByTestId(...)`, `page.getByRole(...)` |
| Cypress | `cy.get(...)`, `cy.find(...)`, `cy.contains(...)` (as selector, not via page) |
| Java | `By.*`, `driver.findElement(...)`, `driver.findElements(...)` |
| C# | `By.*`, `driver.FindElement(...)`, `driver.FindElements(...)` |

### Compliant pattern

```typescript
// tests/e2e/sauce-demo/login.spec.ts — CORRECT
test("invalid login shows error", async ({ loginPage }) => {
  await loginPage.enterCredentials(user.username, user.password);
  await loginPage.submit();
  const error = await loginPage.getErrorMessage();
  expect(error).toContain("Username and password do not match");
});

// ❌ VIOLATION
test("invalid login shows error", async ({ page }) => {
  await page.locator('[data-test="username"]').fill(user.username); // raw selector in test
});
```

### Enforcement

- **Python:** `import-linter` contract + `ruff` custom rule forbidding `By.` imports in `tests/`.
- **TypeScript:** ESLint `no-restricted-syntax` on `page.locator`, `page.getBy*`, `cy.get`.
- **Java:** `ArchUnit` rule: `classes in tests.. must not access By`.
- **C#:** `NetArchTest` rule or Roslyn analyzer on `By.*` usage in test assemblies.

## Consequences

### Positive
- A selector change requires editing one locator file — zero test files touched.
- Test files read as business specifications, approachable by QA leads and product owners.
- DOM coupling is isolated to the locator layer.

### Negative
- Writing a new test requires creating or extending a page object first (slightly slower initial
  authoring, significantly faster long-term maintenance).
- BDD step definitions require the same discipline — steps call page methods, not page API.
