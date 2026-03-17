#!/bin/bash
# Hook: Stop — check for type errors in changed files before Claude stops
# CRITICAL: Check stop_hook_active to prevent infinite loops.
INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
[[ "$STOP_HOOK_ACTIVE" == "true" ]] && exit 0
CHANGED=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.(ts|tsx)$' | grep -v '\.d\.ts$' | grep -v 'node_modules/' || true)
STAGED=$(git diff --cached --name-only 2>/dev/null | grep -E '\.(ts|tsx)$' | grep -v '\.d\.ts$' | grep -v 'node_modules/' || true)
ALL="$CHANGED$STAGED"
[[ -z "$ALL" ]] && exit 0
TSC_OUTPUT=$(npx tsc --noEmit 2>&1 | head -30)
if [[ $? -ne 0 ]]; then
  while IFS= read -r file; do
    if echo "$TSC_OUTPUT" | grep -q "$file"; then
      echo "Type errors in changed files:" >&2
      echo "$TSC_OUTPUT" >&2
      exit 2
    fi
  done <<< "$ALL"
fi
exit 0
