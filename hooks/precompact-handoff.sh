#!/usr/bin/env bash
# Hook: PreCompact — write handoff to DECISIONS.md
set -uo pipefail
GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
ACTIVE=$(cat "$MAIN_REPO/.arc/active-feature" 2>/dev/null || echo "")
[[ -z "$ACTIVE" ]] && exit 0
STATE="$MAIN_REPO/.arc/features/$ACTIVE/STATE.json"
DECISIONS="$MAIN_REPO/.arc/features/$ACTIVE/DECISIONS.md"
[[ ! -f "$STATE" ]] && exit 0
PHASE=$(jq -r '.phase' "$STATE")
TASK=$(jq -r '.task.current' "$STATE")
TOTAL=$(jq -r '.task.total' "$STATE")
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat >> "$DECISIONS" <<EOF

### HANDOFF — $TS (auto: PreCompact)
- **Phase**: $PHASE, task $TASK/$TOTAL
- **Resume**: Run /arc:go to continue
EOF
echo "Handoff written to $DECISIONS"
