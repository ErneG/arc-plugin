#!/usr/bin/env bash
# Hook: WorktreeRemove — tear down port + processes
# Generic variant: no Neon branch deletion, uses configurable DB cleanup
set -uo pipefail

INPUT=$(cat)
WORKTREE_NAME=$(echo "$INPUT" | jq -r '.name // empty' 2>/dev/null)
[[ -z "$WORKTREE_NAME" ]] && exit 0

GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
TIDE_CONFIG="$MAIN_REPO/.tide/config.json"
PORT_MANIFEST="$MAIN_REPO/.tide/worktree-ports"

log() { echo "$*" > /dev/tty 2>/dev/null || true; }

# Kill dev server
if [[ -f "$PORT_MANIFEST" ]]; then
  DEV_PORT=$(grep "^${WORKTREE_NAME}=" "$PORT_MANIFEST" 2>/dev/null | cut -d= -f2 || true)
  [[ -n "$DEV_PORT" ]] && lsof -ti :"$DEV_PORT" | xargs kill 2>/dev/null || true
fi

# Run configurable DB cleanup
DB_STRATEGY=$(jq -r '.db_strategy // "none"' "$TIDE_CONFIG" 2>/dev/null || echo "none")
DB_CLEANUP_CMD=$(jq -r '.db.cleanup_command // empty' "$TIDE_CONFIG" 2>/dev/null || echo "")

if [[ "$DB_STRATEGY" != "none" && -n "$DB_CLEANUP_CMD" ]]; then
  BRANCH_NAME="wt/${WORKTREE_NAME}"
  export TIDE_WORKTREE_NAME="$WORKTREE_NAME"
  export TIDE_DB_BRANCH="$BRANCH_NAME"
  eval "$DB_CLEANUP_CMD" 2>/dev/null || true
fi

# Clean port manifest
[[ -f "$PORT_MANIFEST" ]] && sed -i '' "/^${WORKTREE_NAME}=/d" "$PORT_MANIFEST" 2>/dev/null || true

log "[tide] Cleaned up: $WORKTREE_NAME"
exit 0
