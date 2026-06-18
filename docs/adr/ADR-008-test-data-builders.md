# ADR-008 — Test Data Builders (Programmatic Generation Over Static JSON)

## Status
Accepted — 2026-05-02

## Context

All five repos used static JSON files as the primary test data source:

- `PythonSeleniumProject/data/test_credentials.json`
- `CypressProject/cypress/fixtures/users.json`
- `PlaywrightProject/test-data/users.json`
- etc.

Problems with static JSON test data:

1. **Brittle** — a JSON key typo caused a `KeyError` at runtime, not at authoring time.
2. **Limited coverage** — static files represent a fixed set of scenarios; edge cases require
   adding more rows, making files bloat indefinitely.
3. **No Separation of Concerns** — test logic and data generation were in the same place.
4. **Not type-safe** — TypeScript projects could not statically type the JSON shape.
5. **Poor readability** — `users.json` gave no indication of WHICH test property mattered for
   each scenario.

## Decision

Replace static JSON test data with **Test Data Builders** — programmatic, fluent-API classes
that generate strongly-typed test data on demand.

### Per-stack library

| Stack | Library | Location |
|-------|---------|----------|
| Python | `factory_boy` + `Faker` | `utils/builders/` |
| Java | `Datafaker` | `src/main/java/.../builders/` |
| C# | `Bogus` | `Automation.Framework/Builders/` |
| TypeScript | `@faker-js/faker` | `utils/builders/` |

### API contract (same across all stacks)

```python
# Python
UserBuilder().standard().build()
UserBuilder().locked_out().build()
UserBuilder().with_username("custom").build()

CheckoutBuilder().valid().build()
CheckoutBuilder().with_invalid_postal().build()

ProductBuilder().random(count=3).build()
```

```typescript
// TypeScript
new UserBuilder().standard().build()
new CheckoutBuilder().withInvalidPostal().build()
```

```java
// Java
new UserBuilder().standard().build()
new CheckoutBuilder().withInvalidPostal().build()
```

### What stays as JSON/static data

| Data type | Stays static? | Reason |
|-----------|---------------|--------|
| SauceDemo user credentials | **Yes** — they are fixed by the app | These are not generated; they are known constants |
| API schema definitions | **Yes** | Reference schemas are read-only |
| Visual baselines | **Yes** | Screenshot files, not data |
| Dynamic test input (names, addresses, etc.) | **No** → Builder | Faker generates fresh values per run |

## Consequences

### Positive
- Type-safe at authoring time (TypeScript) or via class attributes (Python dataclasses).
- Builder methods communicate test intent: `.locked_out()` is self-documenting.
- Edge cases are composable: `.with_invalid_postal().with_very_long_name()`.
- Each test run can use fresh data, reducing test-order dependencies.

### Negative
- Initial builder classes require upfront authoring (tracked in tasks 3.5, 5.4, 6.5, 7.5, 8.6).
- Faker output is random — tests that assert on specific generated values must capture the
  value before asserting (`name = builder.build().first_name; assert page.get_name() == name`).
