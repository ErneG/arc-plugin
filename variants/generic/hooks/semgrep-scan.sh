#!/bin/bash
# Hook: PreToolUse (Bash) — Semgrep security scan on git commit
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
echo "$COMMAND" | grep -qE '^git commit' || exit 0
STAGED=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | grep -E '\.(ts|tsx)$' | grep -v 'node_modules/' || true)
[[ -z "$STAGED" ]] && exit 0
SCAN_OUTPUT=$(echo "$STAGED" | xargs semgrep scan --config "p/javascript" --config "p/typescript" --severity ERROR --severity WARNING --quiet --no-git-ignore 2>&1 | head -40)
if [[ $? -ne 0 ]] && echo "$SCAN_OUTPUT" | grep -qE '(error|warning)'; then
  echo "Semgrep findings:" >&2
  echo "$SCAN_OUTPUT" >&2
  exit 2
fi
exit 0
