# ADR-016: Distributed Tracing in Test Execution (OpenTelemetry)

**Status**: ✅ Accepted (Phase 13)
**Date**: 2026-05-04
**Deciders**: QA Architecture Team
**Related**: [ADR-015](./ADR-015-hermetic-test-isolation-strategy.md), [STANDARDS.md](../../STANDARDS.md), [OTEL test-run attribute contract](../OTEL_TEST_RUN_ATTRIBUTES.md)

---

## Context

We have achieved CI/CD parity and centralized Allure reporting across five repos. The next portfolio differentiator is **observability inside the test lifecycle**:

- Identify where time is spent (test setup vs UI actions vs API calls)
- Diagnose failures with trace context (correlate “test failed” → downstream HTTP calls)
- Provide a “production-grade” story for QA architecture maturity

---

## Decision

We will instrument all test stacks with **OpenTelemetry traces**.

### Parent span per test (required)

Each test creates a parent span named `test` with canonical attributes:

- `test.name`
- `test.file` (when available)
- `test.project` / `repo` (when available)

### Export strategy

- **Local dev**: Jaeger via OTLP Collector (`shared-docs/templates/docker-compose.observability.yml`)
- **CI**: OTLP exporter to a vendor backend (Honeycomb free tier preferred)

### Trace ID surfacing

We will surface the `trace_id` into reporting artifacts so reviewers can drill down:

- Python: attach `otel.trace_id` to Allure when Allure is enabled/installed
- Playwright: attach `otel.trace_id` + optional Jaeger URL as test artifacts
- Cypress: print `trace_id` in Node runner logs (and optionally attach to Allure via allure-cypress)
- Java/C#: capture trace_id in logs initially; Allure linking can be added next

---

## Rationale

- **Trace-first debugging**: reduces time-to-root-cause for flaky tests and CI failures.
- **Portfolio signal**: demonstrates senior-level engineering thinking beyond “tests that pass”.
- **Incremental adoption**: parent span per test is the minimum viable standard; deeper auto-instrumentation can be layered later.

---

## Consequences

### ✅ Positive

- Uniform trace context across stacks
- Enables future work:
  - auto-instrument HTTP clients
  - correlate traces to Allure reports hosted on R2
  - build a centralized dashboard that links to traces

### ⚠️ Costs / trade-offs

- Adds dependencies and exporter configuration
- Requires environment variables in CI (OTLP endpoint + credentials)
- Some stacks differ in what can be instrumented easily (browser-side vs runner-side)

---

## Local usage (dev)

1. Start local Jaeger + Collector using templates:

- `shared-docs/templates/docker-compose.observability.yml`
- `shared-docs/templates/otel-collector.config.yml`

2. Set environment variable:

- `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318/v1/traces` (OTLP/HTTP)
- Optional: `JAEGER_UI_URL=http://localhost:16686`

3. Run any test suite; confirm traces appear in Jaeger UI.

---

## Implementation summary (Phase 13)

- Python: pytest lifecycle hook creates `test` span
- Playwright: fixture hook creates `test` span
- Cypress: Node runner creates `cypress.run` span
- Java: JUnit extension creates `test` span; WebDriver extension ensures tracing configured
- C#: xUnit attribute creates `Activity` per test using `ActivitySource`

