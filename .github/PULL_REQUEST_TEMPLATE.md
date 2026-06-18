## Description
<!-- What does this PR do? Link to the relevant task or issue. -->



## Type of change
- [ ] `feat` — new feature (test, page, component, locator)
- [ ] `fix` — bug fix
- [ ] `refactor` — architectural improvement
- [ ] `chore` — dependency update, tooling, CI
- [ ] `docs` — documentation only

---

## 7 Laws Compliance Checklist
> Every PR must satisfy all 7 laws. CI will fail if any is violated.
> Reference: [STANDARDS.md](../STANDARDS.md) · [ADRs](../docs/adr/)

- [ ] **Law 1 — Locator Mirroring:** every new/modified Page has a corresponding Locator file
- [ ] **Law 2 — No assertions in POMs:** `pages/`, `locators/`, `components/` contain zero `assert/expect/should`
- [ ] **Law 3 — No selectors in specs:** `tests/` / `e2e/` contain zero `By.`, `cy.get()`, `page.locator()`
- [ ] **Law 4 — Inheritance ≤ 1 level:** no inheritance chains deeper than `Page → BasePage`
- [ ] **Law 5 — Stateless POMs:** no mutable instance state added beyond `driver/page` and `locators`
- [ ] **Law 6 — Pure utils:** all new helpers in `utils/` are pure/stateless functions or classes
- [ ] **Law 7 — Identical naming:** class/file/method names match the canonical names in `TEST_PARITY.md`

---

## Parity Checklist
> Required for any PR that adds or modifies a test scenario.

- [ ] This PR does **not** add or modify test scenarios (parity check N/A)
- [ ] OR: This scenario exists in `TEST_PARITY.md` with a canonical ID and I have opened / linked PRs in all 5 repos

---

## Architectural Changes
> Required only if this PR changes a cross-cutting pattern (new layer, new tool, etc.)

- [ ] No architectural change
- [ ] OR: A new ADR has been authored / linked: `ADR-XXX` → <!-- link here -->

---

## Sync-Managed Files
> These files are managed by `sync-standards.sh`. Do not edit them directly in this repo.

- [ ] I did **not** modify any sync-managed file (STANDARDS.md, docs/adr/*, lefthook.yml, renovate.json, etc.)
- [ ] OR: I edited the canonical in `shared-docs/`, ran `sync-standards.sh`, and the updated files are included in this PR

---

## Testing
- [ ] `task test` passes locally
- [ ] `task lint` passes locally (0 warnings)
- [ ] `task audit` passes locally (0 violations)

---

## Screenshots / Evidence
<!-- If applicable: test run output, Allure report link, or before/after screenshot -->
