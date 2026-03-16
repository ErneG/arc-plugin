#!/usr/bin/env bash
# Verify module registration integrity across 3 sources of truth:
# 1. Directories in src/modules/
# 2. Entries in medusa-config.ts
# 3. Exports in src/shared/MODULE_NAMES.ts
set -uo pipefail

GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
ERRORS=0

echo "=== Module Integrity Check ==="

# Source 1: directories on disk
DISK_MODULES=$(ls -d "$MAIN_REPO"/src/modules/*/ 2>/dev/null | xargs -I{} basename {} | sort)

# Source 2: modules in medusa-config.ts
CONFIG_MODULES=$(grep -oE 'resolve:\s*"\.\/src\/modules\/[^"]*"' "$MAIN_REPO/medusa-config.ts" 2>/dev/null | \
  sed 's|.*src/modules/||;s|"||g' | sort)

# Source 3: exports in MODULE_NAMES.ts
NAMES_MODULES=$(grep -oE 'export const [A-Z_]+ = "[^"]*"' "$MAIN_REPO/src/shared/MODULE_NAMES.ts" 2>/dev/null | \
  sed 's|.*= "||;s|"||' | sort)

# Cross-reference: on disk but not in config
for mod in $DISK_MODULES; do
  if ! echo "$CONFIG_MODULES" | grep -q "$mod"; then
    echo "WARN: $mod exists on disk but NOT in medusa-config.ts"
    ERRORS=$((ERRORS + 1))
  fi
done

# Cross-reference: in config but not on disk
for mod in $CONFIG_MODULES; do
  if ! echo "$DISK_MODULES" | grep -q "$mod"; then
    echo "FAIL: $mod in medusa-config.ts but directory MISSING"
    ERRORS=$((ERRORS + 1))
  fi
done

# Cross-reference: on disk but not in MODULE_NAMES
for mod in $DISK_MODULES; do
  # Skip common modules that may use different naming
  [[ "$mod" == "node_modules" || "$mod" == "dist" ]] && continue
  MOD_SNAKE=$(echo "$mod" | tr '-' '_')
  if ! echo "$NAMES_MODULES" | grep -qi "$MOD_SNAKE\|$mod"; then
    echo "WARN: $mod on disk but no matching export in MODULE_NAMES.ts"
  fi
done

if [[ $ERRORS -eq 0 ]]; then
  echo "PASS: All modules consistent"
else
  echo "FOUND: $ERRORS issues"
fi
exit $ERRORS
