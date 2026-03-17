#!/usr/bin/env bash
# .tide/scripts/write-progress.sh — Generate human-readable PROGRESS.md for a feature
# Usage: write-progress.sh <feature-name>
# Called by the orchestrator after each task completion.
# Fresh agent sessions read this file to quickly understand where things stand.
set -euo pipefail

FEATURE="${1:?Usage: write-progress.sh <feature-name>}"
GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
TIDE_ROOT="$MAIN_REPO/.tide"
TIDE_DIR="$TIDE_ROOT/features/$FEATURE"
STATE="$TIDE_DIR/STATE.json"
PLAN="$TIDE_DIR/PLAN.md"
PROGRESS="$TIDE_DIR/PROGRESS.md"

if [[ ! -f "$STATE" ]]; then
  exit 0
fi

# Read state
PHASE=$(jq -r '.phase' "$STATE")
STATUS=$(jq -r '.status' "$STATE")
CURRENT_TASK=$(jq -r '.task.current' "$STATE")
TOTAL_TASKS=$(jq -r '.task.total' "$STATE")
BRANCH=$(jq -r '.branch' "$STATE")
DEV_PORT=$(jq -r '.dev_port // 9000' "$STATE")
COMMITS=$(jq -r '.commits | length' "$STATE")
BLOCKED=$(jq -r '.blocked_reason // null' "$STATE")
LAST_ERROR=$(jq -r '.last_error // null' "$STATE")

# Get recent commits on this branch
RECENT_COMMITS=$(git log --oneline -10 --format="- %h %s" 2>/dev/null || echo "- none")

# Get changed files vs base
BASE_SHA=$(jq -r '.base_sha // ""' "$STATE")
if [[ -n "$BASE_SHA" ]]; then
  CHANGED_FILES=$(git diff "$BASE_SHA"...HEAD --stat 2>/dev/null | tail -1 || echo "unknown")
else
  CHANGED_FILES="unknown (no base_sha)"
fi

# Extract gate status
TC=$(jq -r '.gates.typecheck' "$STATE")
TESTS=$(jq -r '.gates.tests' "$STATE")
BROWSER=$(jq -r '.gates.browser' "$STATE")
REVIEW=$(jq -r '.gates.review' "$STATE")

cat > "$PROGRESS" <<PROGRESS
# Progress: $FEATURE

**Phase**: $PHASE ($STATUS)
**Task**: $CURRENT_TASK / $TOTAL_TASKS
**Branch**: $BRANCH
**Dev port**: $DEV_PORT
**Commits**: $COMMITS

## Gates
- Typecheck: $TC
- Tests: $TESTS
- Browser: $BROWSER
- Review: $REVIEW

## Recent Commits
$RECENT_COMMITS

## Changed Files
$CHANGED_FILES
PROGRESS

if [[ "$BLOCKED" != "null" && -n "$BLOCKED" ]]; then
  cat >> "$PROGRESS" <<BLOCKED

## BLOCKED
**Reason**: $BLOCKED
BLOCKED
fi

if [[ "$LAST_ERROR" != "null" && -n "$LAST_ERROR" ]]; then
  cat >> "$PROGRESS" <<ERROR

## Last Error
\`\`\`
$(echo "$LAST_ERROR" | head -20)
\`\`\`
ERROR
fi

# Add next task summary from PLAN.md if available
if [[ -f "$PLAN" && $CURRENT_TASK -le $TOTAL_TASKS ]]; then
  NEXT_TASK=$(grep -A 5 "### Task $CURRENT_TASK:" "$PLAN" 2>/dev/null | head -6 || echo "")
  if [[ -n "$NEXT_TASK" ]]; then
    cat >> "$PROGRESS" <<NEXT

## Next Task
$NEXT_TASK
NEXT
  fi
fi

echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") — Progress updated" >> "$PROGRESS"
