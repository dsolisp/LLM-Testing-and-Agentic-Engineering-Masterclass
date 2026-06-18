# ADR-011 — BDD Coexistence Strategy

## Status
Accepted — 2026-05-02

## Context

The Playwright project includes a BDD layer (Cucumber/Playwright-BDD) with three feature
files (`login.feature`, `cart.feature`, `checkout.feature`) and corresponding step definitions.

**Problems found in the audit:**

1. `tests/bdd/steps/checkout.steps.ts` contained inline `page.getByTestId()` calls — a direct
   violation of Law 3 (no selectors in specs).
2. The BDD layer duplicated scenarios already covered by the standard `*.spec.ts` E2E suite —
   creating maintenance debt with no additional coverage.
3. The cart and checkout features were partially implemented (some steps used hardcoded
   `cy.get()`-style logic rather than page objects).

**Options considered:**

| Option | Verdict | Reason |
|--------|---------|--------|
| Delete all 3 feature files, remove BDD | Rejected | BDD is a differentiating showcase skill for recruiters |
| Keep all 3 features, refactor fully | **Accepted** | Demonstrates full BDD mastery + architectural discipline |
| Keep only login.feature | Rejected | Cart and checkout BDD scenarios show more complexity |

## Decision

**Keep all 3 BDD feature files in the Playwright repo.** Refactor them to comply with all 7
laws. The BDD layer becomes a **flagship showcase feature** — not a duplicate of the E2E spec.

### Architectural rules for BDD steps

1. **Step definitions are treated as test specs** — they must follow Law 3 (no selectors).
2. Step definitions **inject and call page objects** — they do not use `page.locator()` directly.
3. Step definitions **own all assertions** — page object methods return values; steps assert.
4. BDD scenarios **must carry canonical IDs** as tags: `@SAUCE-01` in the feature file maps
   to the same canonical ID in the spec suite (BDD is an alternative expression, not extra coverage).

### Example (compliant)

```gherkin
# login.feature
@SAUCE-01
Scenario: Valid login navigates to inventory
  Given I am on the login page
  When I log in as "standard_user"
  Then I should see the inventory page title "Products"
```

```typescript
// login.steps.ts — CORRECT
When("I log in as {string}", async function (username: string) {
  const user = UserBuilder.fromUsername(username).build();
  await this.loginPage.enterCredentials(user.username, user.password);
  await this.loginPage.submit();
});

Then("I should see the inventory page title {string}", async function (title: string) {
  const actual = await this.inventoryPage.getTitle();
  expect(actual).toBe(title); // assertion ONLY in step, not in page
});
```

### Scope of BDD scenarios

BDD features cover the **SauceDemo critical path only** (SAUCE-01 through SAUCE-06). The
Advanced, API, DB, A11y, and Visual suites use standard spec format — BDD is not required
for those categories.

### Non-Playwright stacks

No other stack in the portfolio has a BDD layer. This is intentional — BDD coexists
**only in Playwright** as a deliberate architectural showcase. Java (SpecFlow was removed)
and C# (Reqnroll covers it in the C# repo) are separate decisions per their own ADRs.

## Consequences

### Positive
- Demonstrates ability to design a compliant BDD layer that respects SoC.
- Three feature files covering login/cart/checkout show realistic BDD usage.
- The architecture is clean enough to serve as a portfolio reference for BDD interviews.

### Negative
- BDD scenarios partially overlap with E2E specs — accepted duplication, serving different
  audiences (living documentation vs. fast regression).
- Step definition refactor required (tracked in task 7.2).
