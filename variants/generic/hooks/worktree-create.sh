#!/usr/bin/env bash
# Hook: WorktreeCreate — auto-provision .env + deps for new worktrees
# Generic variant: no Neon DB branching, no framework-specific env patching
# STDOUT CONTRACT: Print exactly ONE line — the absolute worktree path.
set -uo pipefail  # No -e: we handle errors ourselves to avoid silent death

INPUT=$(cat)
WORKTREE_NAME=$(echo "$INPUT" | jq -r '.name // empty' 2>/dev/null)
[[ -z "$WORKTREE_NAME" ]] && exit 0

# ── Resolve main repo root (works from worktrees) ───────────────────────────
GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
TIDE_CONFIG="$MAIN_REPO/.tide/config.json"
PORT_MANIFEST="$MAIN_REPO/.tide/worktree-ports"

# Read config (with defaults)
PORT_MIN=$(jq -r '.ports.min // 9001' "$TIDE_CONFIG" 2>/dev/null || echo 9001)
PORT_MAX=$(jq -r '.ports.max // 9999' "$TIDE_CONFIG" 2>/dev/null || echo 9999)

# Resolve worktree path — Claude Code creates at .claude/worktrees/<name>
WORKTREE_PATH=$(git worktree list --porcelain 2>/dev/null | grep -A0 "^worktree.*${WORKTREE_NAME}$" | sed 's/^worktree //' | head -1)
if [[ -z "$WORKTREE_PATH" ]]; then
  WORKTREE_PATH="$MAIN_REPO/.claude/worktrees/$WORKTREE_NAME"
fi

log() { echo "$*" > /dev/tty 2>/dev/null || true; }

# ── Port allocation ──────────────────────────────────────────────────────────
allocate_port() {
  local name="$1" range=$((PORT_MAX - PORT_MIN))
  local hash
  hash=$(echo -n "$name" | md5 -q 2>/dev/null || echo -n "$name" | md5sum | cut -d' ' -f1)
  hash=$(echo "$hash" | tr -d -c '0-9' | head -c 5)
  local port=$((PORT_MIN + (hash % range)))
  local attempts=0
  while lsof -i :"$port" > /dev/null 2>&1 && [[ $attempts -lt 10 ]]; do
    port=$((port + 1))
    [[ $port -gt $PORT_MAX ]] && port=$PORT_MIN
    attempts=$((attempts + 1))
  done
  echo "$port"
}

DEV_PORT=$(allocate_port "$WORKTREE_NAME")
log "[tide] Port $DEV_PORT for '$WORKTREE_NAME'"

# ── Copy and patch .env ──────────────────────────────────────────────────────
if [[ -f "$MAIN_REPO/.env" ]]; then
  cp "$MAIN_REPO/.env" "$WORKTREE_PATH/.env"
  [[ -f "$MAIN_REPO/.env.test" ]] && cp "$MAIN_REPO/.env.test" "$WORKTREE_PATH/.env.test"

  # Patch PORT
  if grep -q "^PORT=" "$WORKTREE_PATH/.env"; then
    sed -i '' "s|^PORT=.*|PORT=${DEV_PORT}|" "$WORKTREE_PATH/.env"
  else
    echo "PORT=${DEV_PORT}" >> "$WORKTREE_PATH/.env"
  fi
else
  log "[tide] WARNING: No .env in main repo. Worktree will have no env config."
fi

# ── DB branching (configurable) ──────────────────────────────────────────────
DB_STRATEGY=$(jq -r '.db_strategy // "none"' "$TIDE_CONFIG" 2>/dev/null || echo "none")
DB_BRANCH_CMD=$(jq -r '.db.branch_command // empty' "$TIDE_CONFIG" 2>/dev/null || echo "")

if [[ "$DB_STRATEGY" != "none" && -n "$DB_BRANCH_CMD" ]]; then
  log "[tide] Running DB branch command..."
  BRANCH_NAME="wt/${WORKTREE_NAME}"
  export TIDE_WORKTREE_NAME="$WORKTREE_NAME"
  export TIDE_DB_BRANCH="$BRANCH_NAME"
  export TIDE_WORKTREE_PATH="$WORKTREE_PATH"
  eval "$DB_BRANCH_CMD" 2>/dev/null || log "[tide] WARNING: DB branch command failed."
fi

# ── Install dependencies ─────────────────────────────────────────────────────
if [[ -f "$WORKTREE_PATH/package.json" ]]; then
  log "[tide] Installing dependencies..."
  INSTALL_CMD=$(jq -r '.install_command // empty' "$TIDE_CONFIG" 2>/dev/null || echo "")
  if [[ -n "$INSTALL_CMD" ]]; then
    (cd "$WORKTREE_PATH" && eval "$INSTALL_CMD") > /dev/null 2>&1 || \
      log "[tide] WARNING: install command failed."
  elif [[ -f "$WORKTREE_PATH/yarn.lock" ]]; then
    (cd "$WORKTREE_PATH" && yarn install) > /dev/null 2>&1 || \
      log "[tide] WARNING: yarn install failed."
  elif [[ -f "$WORKTREE_PATH/pnpm-lock.yaml" ]]; then
    (cd "$WORKTREE_PATH" && pnpm install) > /dev/null 2>&1 || \
      log "[tide] WARNING: pnpm install failed."
  elif [[ -f "$WORKTREE_PATH/package-lock.json" ]]; then
    (cd "$WORKTREE_PATH" && npm install) > /dev/null 2>&1 || \
      log "[tide] WARNING: npm install failed."
  fi
  log "[tide] Done"
fi

# ── Port manifest ────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$PORT_MANIFEST")"
touch "$PORT_MANIFEST"
sed -i '' "/^${WORKTREE_NAME}=/d" "$PORT_MANIFEST" 2>/dev/null || true
echo "${WORKTREE_NAME}=${DEV_PORT}" >> "$PORT_MANIFEST"

log "[tide] Ready: $WORKTREE_PATH (port $DEV_PORT)"

# STDOUT: absolute path (required contract)
echo "$WORKTREE_PATH"
