# ADR-019 — AI in Test Automation (OSS-first)

## Status

Accepted — 2026-05-21

## Context

The portfolio may adopt AI for authoring, self-healing locators, flaky classification, and CI
triage. Without rules, AI would violate **Law 3** (selectors in specs), increase CI cost, and
mask real product failures.

## Decision

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | **Dev-time AI on by default (local)** — Playwright MCP / Test Agents, optional Ollama | High ROI; no PR gate token burn |
| 2 | **Runtime healing off in PR CI** — `AI_HEALING_ENABLED=false` on `ci.yml` | Deterministic merges |
| 3 | **Runtime healing optional on nightly** — `AI_HEALING_ENABLED=true` on `nightly.yml` / `workflow_dispatch` | Demonstrates capability without blocking PRs |
| 4 | **Heal at locator/page layer only** — never in `tests/` specs | Preserves Law 3 |
| 5 | **Promote healed selectors via reviewed PR** — `scripts/promote-healed-locator.*` updates `locators/` | Keeps locator files source of truth |
| 6 | **Provider: OSS-first** — `ollama` (local), `groq` (CI optional); API keys only in env/secrets | No keys in git |
| 7 | **Cost cap** — `AI_MAX_HEALS_PER_RUN` default `10` | Prevents runaway LLM calls |
| 8 | **Observability** — log `test.heal.applied=true` on OTel span when heal used | Aligns with ADR-016 |
| 9 | **Scope** — healing for **locator drift** only; not assertions, data, or timing | Parity-safe (ADR-007) |
| 10 | **Commercial AI UI tools** — Cypress Cloud `cy.prompt`, Applitools: **out of scope** for default portfolio path | OSS-first policy |

### Healing contract (all stacks)

```
resolve(locatorKey, fallbacks[], context) → Locator | WebElement
```

1. Try primary locator from `locators/`
2. Try ordered heuristic fallbacks (role, placeholder, test id)
3. If `AI_HEALING_ENABLED` and provider configured, call OSS heal library
4. Cache result under `.ai-heal-cache/` (gitignored)
5. Emit Allure step / log entry; do not auto-commit locator file changes

## Consequences

### Positive

- Faster scenario authoring and lower locator maintenance cost.
- Consistent cross-repo policy for recruiters and clients.

### Negative

- Optional dependencies and local Ollama setup for full healing path.
- Healenium-style proxy healing remains deferred (ADR note only).

**See also:** [PORTFOLIO_AI_ROADMAP.md](../PORTFOLIO_AI_ROADMAP.md), [AI_ROADMAP.md](../AI_ROADMAP.md) (index), `.env.ai.example` in `shared-docs/`.
