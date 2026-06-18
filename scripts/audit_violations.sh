#!/usr/bin/env bash
# audit_violations.sh — per-repo violation audit
# SYNC-MANAGED — do not edit in project repos. Edit in shared-docs/ and run sync-standards.sh
# See: shared-docs/docs/adr/ADR-013-multirepo-sync-strategy.md
#
# Usage: bash scripts/audit_violations.sh [--json] [--strict]
# Exit code 0 = no violations. Non-zero = violations found.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
JSON_MODE=false
VIOLATIONS=0
REPORT=()

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_MODE=true
done

log_violation() {
  local law="$1" file="$2" line="$3" match="$4"
  VIOLATIONS=$((VIOLATIONS + 1))
  REPORT+=("{\"law\":\"$law\",\"file\":\"$file\",\"line\":$line,\"match\":\"$match\"}")
  if [[ "$JSON_MODE" == "false" ]]; then
    echo -e "${RED}❌ $law${NC} → $file:$line → $match"
  fi
}

log_info() { [[ "$JSON_MODE" == "false" ]] && echo -e "${YELLOW}▶ $1${NC}"; }

# ── Law 1: Locator Mirroring 1:1 ───────────────────────────────────────────
log_info "Law 1: Checking locator mirroring 1:1..."
if [[ -d "$REPO_ROOT/pages" && -d "$REPO_ROOT/locators" ]]; then
  while IFS= read -r page_file; do
    relative="${page_file#$REPO_ROOT/pages/}"
    # Derive expected locator path — handle each stack extension separately
    if [[ "$page_file" == *.page.ts ]]; then
      locator_file="$REPO_ROOT/locators/${relative/.page.ts/.locators.ts}"
    elif [[ "$page_file" == *_page.py ]]; then
      locator_file="$REPO_ROOT/locators/${relative/_page.py/_locators.py}"
    elif [[ "$page_file" == *Page.java ]]; then
      locator_file="$REPO_ROOT/locators/${relative/Page.java/Locators.java}"
    elif [[ "$page_file" == *Page.cs ]]; then
      locator_file="$REPO_ROOT/locators/${relative/Page.cs/Locators.cs}"
    else
      continue
    fi
    if [[ ! -f "$locator_file" ]]; then
      log_violation "Law 1" "$page_file" "0" "No matching locator file found"
    fi
  done < <(find "$REPO_ROOT/pages" -type f \( -name "*_page.py" -o -name "*.page.ts" -o -name "*Page.java" -o -name "*Page.cs" \) 2>/dev/null)
fi

# ── Law 2: No assertions in pages/locators/components ──────────────────────
log_info "Law 2: Checking no assertions in pages/locators/components..."
ASSERT_DIRS=("pages" "locators" "components" "Pages" "Locators" "Components")
# Patterns are stack-specific — this version covers all stacks
ASSERT_PATTERNS='^\s*(assert\b|assert_that|assertThat|assertEquals|Assert\.|\.Should\(\)|expect\(|\.should\(|toBeVisible|toHaveText)'

for dir in "${ASSERT_DIRS[@]}"; do
  [[ ! -d "$REPO_ROOT/$dir" ]] && continue
  while IFS= read -r match_line; do
    file=$(echo "$match_line" | cut -d: -f1)
    line=$(echo "$match_line" | cut -d: -f2)
    match=$(echo "$match_line" | cut -d: -f3-)
    log_violation "Law 2" "$file" "$line" "$match"
  done < <(grep -rn --binary-files=without-match -E "$ASSERT_PATTERNS" \
    "$REPO_ROOT/$dir" 2>/dev/null || true)
done

# ── Law 3: No selectors in tests ───────────────────────────────────────────
log_info "Law 3: Checking no selector literals in tests/..."
# NOTE: find_element/find_elements excluded — legitimate in unit/integration test helpers
SELECTOR_PATTERNS='(By\.[A-Z]|driver\.findElement|driver\.FindElement|page\.locator\(|page\.getBy[A-Z]|cy\.get\(|cy\.find\()'
TEST_DIRS=("tests" "e2e" "specs" "cypress/e2e")

for dir in "${TEST_DIRS[@]}"; do
  [[ ! -d "$REPO_ROOT/$dir" ]] && continue
  while IFS= read -r match_line; do
    file=$(echo "$match_line" | cut -d: -f1)
    line=$(echo "$match_line" | cut -d: -f2)
    match=$(echo "$match_line" | cut -d: -f3-)
    # Skip conftest.py, fixture files, unit tests, performance/load tests, and BDD step definitions
    [[ "$file" == *"conftest"* || "$file" == *"fixture"* || "$file" == *"unit"* || "$file" == *"performance"* || "$file" == *"locustfile"* || "$file" == *"benchmark"* || "$file" == *"steps"* || "$file" == *"bdd"* ]] && continue
    # Skip lines that are single-line commented (// or #)
    trimmed=$(echo "$match" | sed 's/^[[:space:]]*//')
    [[ "$trimmed" == "//"* || "$trimmed" == "#"* ]] && continue
    # Skip lines inside /* */ block comments: walk file up to matched line tracking open/close
    if [[ -f "$file" && "$line" =~ ^[0-9]+$ ]]; then
      _in_block=0
      while IFS= read -r _src; do
        [[ "$_src" == *"/*"* ]] && _in_block=1
        [[ "$_src" == *"*/"* ]] && _in_block=0
      done < <(head -n "$line" "$file" 2>/dev/null)
      [[ "$_in_block" -eq 1 ]] && continue
    fi
    log_violation "Law 3" "$file" "$line" "$match"
  done < <(grep -rn --binary-files=without-match -E "$SELECTOR_PATTERNS" \
    "$REPO_ROOT/$dir" \
    --exclude-dir=__pycache__ \
    --exclude-dir=bin \
    --exclude-dir=obj \
    --exclude-dir=Debug \
    --exclude-dir=Release \
    --exclude-dir=allure-results \
    2>/dev/null || true)
done

# ── Search-engine references (global) ──────────────────────────────────────
log_info "Checking for search-engine references..."
while IFS= read -r match_line; do
  file=$(echo "$match_line" | cut -d: -f1)
  line=$(echo "$match_line" | cut -d: -f2)
  match=$(echo "$match_line" | cut -d: -f3-)
  log_violation "Decommission" "$file" "$line" "search-engine reference: $match"
done < <(grep -rn --binary-files=without-match -E "(bing|google\.com|SearchEngine|search_engine)" \
  "$REPO_ROOT" \
  --include="*.py" --include="*.java" --include="*.cs" --include="*.ts" \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude-dir=__pycache__ \
  --exclude-dir=target \
  --exclude-dir=bin \
  --exclude-dir=obj \
  --exclude-dir=.venv \
  --exclude-dir=venv \
  --exclude-dir=venv-enhanced \
  --exclude-dir=.venv-enhanced \
  --exclude-dir=allure-results \
  2>/dev/null || true)

# ── Summary ────────────────────────────────────────────────────────────────
if [[ "$JSON_MODE" == "true" ]]; then
  echo "{\"violations\":$VIOLATIONS,\"details\":[$(IFS=,; echo "${REPORT[*]}")]}"
else
  echo ""
  if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}✅ audit_violations.sh — 0 violations found.${NC}"
  else
    echo -e "${RED}❌ audit_violations.sh — $VIOLATIONS violation(s) found. Fix before merging.${NC}"
  fi
fi

exit $VIOLATIONS
