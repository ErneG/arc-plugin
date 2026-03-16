#!/usr/bin/env bash
# Verify that all API routes using req.validatedBody have matching zod schemas
set -uo pipefail

GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
ERRORS=0

echo "=== Route Validation Check ==="

MIDDLEWARES="$MAIN_REPO/src/api/middlewares.ts"
if [[ ! -f "$MIDDLEWARES" ]]; then
  echo "WARN: src/api/middlewares.ts not found"
  exit 0
fi

# Find all route files using validatedBody
ROUTES_WITH_BODY=$(grep -rl 'req\.validatedBody' "$MAIN_REPO/src/api/" 2>/dev/null || true)

for route_file in $ROUTES_WITH_BODY; do
  # Extract the route path from file location
  REL_PATH=$(echo "$route_file" | sed "s|$MAIN_REPO/src/api/||" | sed 's|/route\.ts$||' | sed 's|\[id\]|:id|g')
  ROUTE_PATH="/$REL_PATH"

  # Check if middleware entry exists for this route
  if ! grep -q "\"$ROUTE_PATH\"\|'$ROUTE_PATH'" "$MIDDLEWARES" 2>/dev/null; then
    # Try without leading slash variations
    CLEAN_PATH=$(echo "$ROUTE_PATH" | sed 's|^/||')
    if ! grep -q "$CLEAN_PATH" "$MIDDLEWARES" 2>/dev/null; then
      echo "WARN: $route_file uses validatedBody but no middleware entry for $ROUTE_PATH"
      ERRORS=$((ERRORS + 1))
    fi
  fi
done

# Find POST/PUT routes without validation
POST_ROUTES=$(grep -rl 'export const POST\|export const PUT\|export const PATCH' "$MAIN_REPO/src/api/" 2>/dev/null || true)
for route_file in $POST_ROUTES; do
  if ! grep -q 'validatedBody' "$route_file" 2>/dev/null; then
    echo "WARN: $(echo "$route_file" | sed "s|$MAIN_REPO/||") has POST/PUT handler without req.validatedBody"
  fi
done

if [[ $ERRORS -eq 0 ]]; then
  echo "PASS: All validated routes have middleware entries"
else
  echo "FOUND: $ERRORS issues"
fi
exit 0
