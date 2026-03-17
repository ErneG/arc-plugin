#!/bin/bash
# Hook: SessionStart (compact) — re-inject context after compaction
GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
ACTIVE=$(cat "$MAIN_REPO/.tide/active-feature" 2>/dev/null || echo "")
STATE="$MAIN_REPO/.tide/features/$ACTIVE/STATE.json"
echo "=== Post-Compaction Context ==="
echo "Branch: $(git branch --show-current 2>/dev/null)"
echo "Working dir: $(pwd)"
if [[ -n "$ACTIVE" && -f "$STATE" ]]; then
  echo "Feature: $ACTIVE"
  echo "Phase: $(jq -r '.phase' "$STATE") ($(jq -r '.status' "$STATE"))"
  echo "Task: $(jq -r '.task.current' "$STATE") / $(jq -r '.task.total' "$STATE")"
  echo "Port: $(jq -r '.dev_port // 9000' "$STATE")"
  echo "Key files: STATE=$STATE, PLAN=$MAIN_REPO/.tide/features/$ACTIVE/PLAN.md"
fi
echo "=== End Context ==="
exit 0
