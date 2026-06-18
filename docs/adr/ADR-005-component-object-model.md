# ADR-005 — Component Object Model (COM)

## Status
Accepted — 2026-05-02

## Context

The SauceDemo application (and the advanced practice site) contain UI widgets that appear on
multiple pages — the hamburger menu, the cart badge, the product card, the header, and modal
overlays. Without a Component Object Model, these widgets were either:

1. **Duplicated** — each page that used the header redeclared its selectors and methods.
2. **Placed in BasePage** — inflating BasePage with widget logic unrelated to all pages.
3. **Ignored** — tests interacted with widgets through ad-hoc selectors, violating Law 3.

## Decision

Introduce a `components/` layer between `pages/` and `locators/`:

```
components/
├── header.component.py          (Python)
├── burger_menu.component.py
├── product_card.component.py
├── cart_badge.component.py
├── modal.component.py
└── dropdown.component.py

locators/components/
├── header_locators.py
├── burger_menu_locators.py
└── ...
```

### Rules for Components

1. **A Component is injected into a Page** — Pages do not instantiate Components; they receive
   them via constructor injection or a factory (same driver is shared).
2. **A Component has its own Locator file** — same 1:1 mirroring rule as pages (Law 1).
3. **A Component has zero assertions** — same rule as pages (Law 2).
4. **A Component inherits from `BaseComponent`** — which receives `driver/page` only.
   `BaseComponent` does NOT extend `BasePage`.
5. **A Component is stateless** — same rule as pages (Law 5).

### When to use a Component vs. a Page method

| Situation | Use |
|-----------|-----|
| Widget appears on ≥ 2 pages | Component |
| Widget has > 3 interactable elements | Component |
| Logic is specific to one page | Page method |
| Widget is a simple button with one action | Page method |

### Example (Python)

```python
# components/header.component.py
class HeaderComponent:
    def __init__(self, driver, locators: HeaderLocators):
        self.driver = driver
        self.locators = locators

    def open_menu(self) -> None:
        self.driver.find_element(*self.locators.BURGER_MENU).click()

    def get_cart_count(self) -> int:
        badge = self.driver.find_element(*self.locators.CART_BADGE)
        return int(badge.text) if badge else 0

# pages/sauce/inventory_page.py
class InventoryPage(BasePage):
    def __init__(self, driver, locators, header: HeaderComponent):
        super().__init__(driver, locators)
        self.header = header   # composed, not inherited
```

## Consequences

### Positive
- Widget changes require editing one Component file — zero Page files touched.
- Components are independently testable (inject a mock driver).
- Pages become thinner and more focused on page-level flows.

### Negative
- Initial setup requires identifying and extracting all reusable widgets (one-time cost,
  tracked in task 3.4, 5.3, 6.4, 7.4, 8.5).
- Constructor injection increases constructor signature length — mitigated by using
  a `PageFactory` or fixture that wires components automatically.
