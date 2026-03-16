#!/usr/bin/env bash
# Hook: WorktreeCreate — auto-provision Neon DB branch + .env + deps for new worktrees
# STDOUT CONTRACT: Print exactly ONE line — the absolute worktree path.
set -uo pipefail  # No -e: we handle errors ourselves to avoid silent death

INPUT=$(cat)
WORKTREE_NAME=$(echo "$INPUT" | jq -r '.name // empty' 2>/dev/null)
[[ -z "$WORKTREE_NAME" ]] && exit 0

# ── Resolve main repo root (works from worktrees) ───────────────────────────
# git rev-parse --show-toplevel returns the WORKTREE root, not the main repo.
# We need the main repo for .tide/config.json. Use --git-common-dir.
GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
TIDE_CONFIG="$MAIN_REPO/.tide/config.json"
PORT_MANIFEST="$MAIN_REPO/.tide/worktree-ports"

# Read config (with defaults)
NEON_PROJECT=$(jq -r '.neon.project_id // "old-breeze-92687906"' "$TIDE_CONFIG" 2>/dev/null || echo "old-breeze-92687906")
PORT_MIN=$(jq -r '.ports.min // 9001' "$TIDE_CONFIG" 2>/dev/null || echo 9001)
PORT_MAX=$(jq -r '.ports.max // 9999' "$TIDE_CONFIG" 2>/dev/null || echo 9999)
DB_STRATEGY=$(jq -r '.db_strategy // "neon"' "$TIDE_CONFIG" 2>/dev/null || echo "neon")

# Resolve worktree path — Claude Code creates at .claude/worktrees/<name>
# The hook fires AFTER the worktree is created, so we can find it via git
WORKTREE_PATH=$(git worktree list --porcelain 2>/dev/null | grep -A0 "^worktree.*${WORKTREE_NAME}$" | sed 's/^worktree //' | head -1)
if [[ -z "$WORKTREE_PATH" ]]; then
  # Fall back to standard location
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
  sed -i '' "s|MEDUSA_BACKEND_URL=.*|MEDUSA_BACKEND_URL=http://localhost:${DEV_PORT}|" "$WORKTREE_PATH/.env"
  sed -i '' "s|WEBAUTHN_ORIGIN=.*|WEBAUTHN_ORIGIN=http://localhost:${DEV_PORT}|" "$WORKTREE_PATH/.env"
else
  log "[tide] WARNING: No .env in main repo. Worktree will have no env config."
fi

# ── Neon DB branch ───────────────────────────────────────────────────────────
NEON_BRANCH="wt/${WORKTREE_NAME}"
if [[ "$DB_STRATEGY" == "neon" ]]; then
  if ! neonctl branches list --project-id "$NEON_PROJECT" > /dev/null 2>&1; then
    log "[tide] WARNING: neonctl auth failed. Run 'neonctl auth'. Using main DATABASE_URL."
  else
    if ! neonctl branches list --project-id "$NEON_PROJECT" 2>/dev/null | grep -q "$NEON_BRANCH"; then
      log "[tide] Creating Neon branch '$NEON_BRANCH'..."
      neonctl branches create --project-id "$NEON_PROJECT" --name "$NEON_BRANCH" --parent production > /dev/null 2>&1 || \
        log "[tide] WARNING: Neon branch creation failed."
    fi
    NEON_CONN=$(neonctl connection-string --project-id "$NEON_PROJECT" --branch "$NEON_BRANCH" --pooled 2>/dev/null || echo "")
    if [[ -n "$NEON_CONN" && -f "$WORKTREE_PATH/.env" ]]; then
      sed -i '' "s|^DATABASE_URL=.*|DATABASE_URL=${NEON_CONN}|" "$WORKTREE_PATH/.env"
      log "[tide] Patched DATABASE_URL with Neon branch"
    fi
  fi
fi

# ── Install dependencies ─────────────────────────────────────────────────────
if [[ -f "$WORKTREE_PATH/package.json" ]]; then
  log "[tide] Installing dependencies..."
  (cd "$WORKTREE_PATH" && yarn install) > /dev/null 2>&1 || \
    log "[tide] WARNING: yarn install failed."
  log "[tide] Done"
fi

# ── Port manifest ────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$PORT_MANIFEST")"
touch "$PORT_MANIFEST"
sed -i '' "/^${WORKTREE_NAME}=/d" "$PORT_MANIFEST" 2>/dev/null || true
echo "${WORKTREE_NAME}=${DEV_PORT}" >> "$PORT_MANIFEST"

log "[tide] Ready: $WORKTREE_PATH (port $DEV_PORT, db $NEON_BRANCH)"

# STDOUT: absolute path (required contract)
echo "$WORKTREE_PATH"
