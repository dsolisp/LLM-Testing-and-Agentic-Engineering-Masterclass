# ADR-006 — Cypress Multi-Tab Strategy (window.open Stub)

## Status
Accepted — 2026-05-02

## Context

The Advanced Interactions suite includes two scenarios that verify behavior when the
application opens a new browser tab:

- **E5:** Open new tab via `<a target="_blank">` and validate the new tab's heading.
- **E6:** Open new tab via `window.open()` (JavaScript) and validate the new tab's heading.

Cypress architecturally **does not support multiple browser tabs or windows** in the same
test run. Its single-origin, single-page model means `cy.window()` always refers to the
current page — there is no mechanism to switch to a tab opened by the application.

### Alternatives considered

| Option | Verdict | Reason |
|--------|---------|--------|
| `cypress-multi-session` plugin | Rejected | Experimental, unmaintained, brittle |
| CDP-level tab switching | Rejected | Requires Chrome-only setup, breaks cross-browser |
| Skip the scenarios in Cypress | Rejected | Breaks test parity (Law 7) and hides a capability gap |
| Stub `window.open` + validate URL intent | **Accepted** | Deterministic, fast, transparent about limitation |

## Decision

For scenarios E5 and E6 in the Cypress Advanced suite, use a **documented stub strategy**:

1. **Intercept** `window.open` before the action: `cy.window().then(win => { cy.stub(win, 'open').as('windowOpen') })`.
2. **Trigger** the action (click the link or button).
3. **Assert** that `window.open` was called with the expected URL.
4. **Navigate** to the URL directly in the same tab: `cy.visit(expectedUrl)`.
5. **Assert** the heading in the now-current tab.

```typescript
// cypress/e2e/advanced/windows.cy.ts
it("E5 — opens new tab via link and validates destination", () => {
  cy.window().then(win => cy.stub(win, "open").as("newTab"));
  windowsPage.clickNewTabLink();
  cy.get("@newTab").should("have.been.calledWith", Cypress.env("WINDOWS_NEW_URL"));
  cy.visit(Cypress.env("WINDOWS_NEW_URL"));
  windowsPage.getNewWindowHeading().should("contain", "New Window");
});
```

### Mandatory documentation in test file

Every test using this stub MUST include the following comment block:

```typescript
/**
 * CYPRESS LIMITATION — ADR-006
 * Cypress cannot natively control multiple browser tabs.
 * This test stubs window.open() to capture the target URL, then navigates to it
 * in the same tab. Equivalent multi-tab behavior is tested in Playwright (E5/E6)
 * and Python/Java/C# Selenium (using driver.window_handles).
 * See: shared-docs/docs/adr/ADR-006-cypress-multitab-stub.md
 */
```

### Cross-stack parity clarification

| Stack | Multi-tab strategy |
|-------|--------------------|
| Python (Selenium) | `driver.window_handles` + `driver.switch_to.window()` |
| Java (Selenium) | `driver.getWindowHandles()` + `driver.switchTo().window()` |
| C# (Selenium) | `driver.WindowHandles` + `driver.SwitchTo().Window()` |
| Playwright | `context.waitForEvent("page")` |
| Cypress | **Stub** (this ADR) — documented limitation |

The canonical test ID (E5, E6) is present in all 5 stacks. Cypress covers the URL intent
validation; the actual handle-switching behavior is covered by the other 4 stacks.

## Consequences

### Positive
- Test parity is maintained (all 5 stacks have E5 and E6).
- The limitation is transparent — documented in the ADR, the test file, and the README.
- The stub approach is deterministic and fast (no actual tab opened).

### Negative
- Cypress E5/E6 do not fully replicate the browser UX (no real tab switching).
  This is an **honest gap**, not hidden behavior.
- Recruiters and reviewers will see the stub — the comment block and README note turn
  this into a demonstrated architectural awareness rather than a deficiency.
