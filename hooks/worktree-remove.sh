#!/usr/bin/env bash
# Hook: WorktreeRemove — tear down Neon branch + port + processes
set -uo pipefail

INPUT=$(cat)
WORKTREE_NAME=$(echo "$INPUT" | jq -r '.name // empty' 2>/dev/null)
[[ -z "$WORKTREE_NAME" ]] && exit 0

GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
ARC_CONFIG="$MAIN_REPO/.arc/config.json"
PORT_MANIFEST="$MAIN_REPO/.arc/worktree-ports"

NEON_PROJECT=$(jq -r '.neon.project_id // "old-breeze-92687906"' "$ARC_CONFIG" 2>/dev/null || echo "old-breeze-92687906")
DB_STRATEGY=$(jq -r '.db_strategy // "neon"' "$ARC_CONFIG" 2>/dev/null || echo "neon")

log() { echo "$*" > /dev/tty 2>/dev/null || true; }

# Kill dev server
if [[ -f "$PORT_MANIFEST" ]]; then
  DEV_PORT=$(grep "^${WORKTREE_NAME}=" "$PORT_MANIFEST" 2>/dev/null | cut -d= -f2 || true)
  [[ -n "$DEV_PORT" ]] && lsof -ti :"$DEV_PORT" | xargs kill 2>/dev/null || true
fi

# Delete Neon branch
if [[ "$DB_STRATEGY" == "neon" ]]; then
  NEON_BRANCH="wt/${WORKTREE_NAME}"
  neonctl branches delete "$NEON_BRANCH" --project-id "$NEON_PROJECT" 2>/dev/null || true
fi

# Clean port manifest
[[ -f "$PORT_MANIFEST" ]] && sed -i '' "/^${WORKTREE_NAME}=/d" "$PORT_MANIFEST" 2>/dev/null || true

log "[arc] Cleaned up: $WORKTREE_NAME"
exit 0
