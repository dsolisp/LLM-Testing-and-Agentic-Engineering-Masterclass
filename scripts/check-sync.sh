#!/usr/bin/env bash
# check-sync.sh — per-repo sync drift detector
# SYNC-MANAGED — do not edit in project repos. Edit in shared-docs/ and run sync-standards.sh
# See: shared-docs/docs/adr/ADR-013-multirepo-sync-strategy.md
#
# Verifies that SYNC-MANAGED files in this repo match the SHA-256 hashes in manifest.sha256.
# Run automatically in CI. Run manually before opening a PR that touches synced files.
#
# Usage: bash scripts/check-sync.sh [--fix-hint]
# Exit code 0 = in sync. Non-zero = drift detected.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/manifest.sha256"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
DRIFT=0

if [[ ! -f "$MANIFEST" ]]; then
  echo -e "${YELLOW}⚠️  manifest.sha256 not found. Run sync-standards.sh to generate it.${NC}"
  exit 1
fi

echo -e "${YELLOW}▶ Checking sync manifest...${NC}"

while IFS="  " read -r expected_hash file_path; do
  # Skip comment lines
  [[ "$expected_hash" == "#"* ]] && continue
  [[ -z "$expected_hash" ]] && continue

  full_path="$REPO_ROOT/$file_path"

  if [[ ! -f "$full_path" ]]; then
    echo -e "${RED}❌ MISSING: $file_path${NC}"
    DRIFT=$((DRIFT + 1))
    continue
  fi

  actual_hash=$(sha256sum "$full_path" 2>/dev/null | cut -d' ' -f1 \
    || shasum -a 256 "$full_path" 2>/dev/null | cut -d' ' -f1)

  if [[ "$actual_hash" != "$expected_hash" ]]; then
    echo -e "${RED}❌ DRIFT:   $file_path${NC}"
    echo    "   Expected: $expected_hash"
    echo    "   Actual:   $actual_hash"
    DRIFT=$((DRIFT + 1))
  fi
done < "$MANIFEST"

echo ""
if [[ $DRIFT -eq 0 ]]; then
  echo -e "${GREEN}✅ check-sync.sh — All sync-managed files are in sync.${NC}"
else
  echo -e "${RED}❌ check-sync.sh — $DRIFT file(s) have drifted from the canonical.${NC}"
  echo ""
  echo "   To fix: edit the canonical file in shared-docs/, then run:"
  echo "   $ bash /path/to/Personal/scripts/sync-standards.sh"
  echo ""
  echo "   Do NOT edit sync-managed files directly in this repo."
fi

exit $DRIFT
