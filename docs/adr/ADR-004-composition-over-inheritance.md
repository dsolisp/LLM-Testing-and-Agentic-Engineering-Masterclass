# ADR-004 — Composition Over Inheritance (≤ 1 Inheritance Level)

## Status
Accepted — 2026-05-02

## Context

Inheritance chains in Page Objects create hidden dependencies that are difficult to debug
and impossible to paralelise safely. The audit found chains such as:

```
# Python (before refactor)
class SauceDemoPage(BasePage):      # level 1
    class LoginPage(SauceDemoPage): # level 2 — VIOLATION
```

```java
// Java (before refactor)
class SaucePage extends BasePage { ... }
class LoginPage extends SaucePage { ... }  // level 2 — VIOLATION
```

Problems caused:

1. **"Where is this method?"** — developers had to trace the inheritance chain to understand
   which class owned a method.
2. **Tight coupling** — changing a method signature in `SauceDemoPage` silently broke all
   subclasses.
3. **Parallelism issues** — shared mutable state in intermediate classes caused flaky tests
   when run in parallel.
4. **Untestable units** — intermediate classes could not be unit-tested in isolation.

## Decision

### Inheritance rule
Page Objects, Components, and Locator files may extend **at most one base class** (`BasePage`,
`BaseComponent`, or equivalent). No intermediate abstract pages.

```
Allowed:   LoginPage → BasePage
Violation: LoginPage → SaucePage → BasePage
```

### Composition rule
Shared behavior previously in intermediate classes is extracted to **helper/mixin classes**
and **composed** into `BasePage` or injected directly:

| Shared behavior | Old approach | New approach |
|-----------------|-------------|--------------|
| Waits and retries | `SaucePage.wait_for(...)` | `WaitMixin` / `WaitHelpers` class |
| Click + type actions | `SaucePage.safe_click(...)` | `ActionMixin` / `ActionHelpers` class |
| Navigation | `SaucePage.go_to(...)` | `NavigationMixin` / `NavigationHelpers` class |
| Screenshots | `SaucePage.take_screenshot(...)` | `ScreenshotMixin` / `ScreenshotHelpers` class |

### Per-stack implementation

| Stack | Mechanism |
|-------|-----------|
| Python | Mixins via multiple inheritance on `BasePage` only (`class BasePage(WaitMixin, ActionMixin, ...)`) |
| Java | Helper classes injected into `BasePage` constructor |
| C# | Helper classes injected into `BasePage` constructor |
| TypeScript (PW/Cy) | Helper classes composed in `BasePage` constructor |

## Consequences

### Positive
- `BasePage` is the only parent — any method's origin is immediately obvious.
- Helper classes can be unit-tested in isolation without a driver.
- Adding new shared behavior = add a new helper class; zero changes to existing pages.
- Flat hierarchy is safe for parallel test execution.

### Negative
- Requires extracting existing shared behavior from intermediate classes (one-time refactor,
  tracked in Phases 3, 5, 6, 7, 8).
- Multiple inheritance for Python mixins requires careful MRO awareness — documented in
  per-stack guides.

**Enforcement:** ArchUnit (Java) · NetArchTest (C#) · ESLint (TS) · custom ruff plugin (Python).
