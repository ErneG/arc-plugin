---
name: browser-verify
description: >
  Verify UI changes using agent-browser. Opens the Medusa admin or storefront,
  checks pages load, forms work, console is clean. Token-efficient (280 tokens/page).
  Triggers: "browser verify", "check the UI", "verify the page", "does it look right".
allowed-tools: Bash, Read, Grep, Glob
---

# /browser-verify — UI Verification with agent-browser

Verify UI changes are working correctly using agent-browser CLI.
Uses accessibility tree snapshots (280 tokens/page) — not screenshots.

## Environment Discovery

Before navigating, find the dev server port:

```bash
# Read from .env in worktree root
PORT=$(grep "^PORT=" .env 2>/dev/null | cut -d= -f2)
PORT=${PORT:-9000}  # Default to 9000
```

- Admin UI: `http://localhost:$PORT/app`
- Store API: `http://localhost:$PORT/store`

## Check if Server is Running

```bash
curl -sf http://localhost:$PORT/health > /dev/null 2>&1
```

If not running, tell the user to start it with `yarn dev` first. Do NOT start it yourself.

## Core Verification Flow

### 1. Open and snapshot

```bash
agent-browser open "http://localhost:$PORT/app" && \
agent-browser wait --load networkidle && \
agent-browser snapshot -i -c
```

The `-i` flag shows only interactive elements. The `-c` flag removes empty structural nodes. This keeps output minimal.

### 2. Check for errors

```bash
agent-browser errors
agent-browser console
```

Report any JavaScript errors or warnings.

### 3. Navigate to specific pages

```bash
agent-browser open "http://localhost:$PORT/app/products" && \
agent-browser wait --load networkidle && \
agent-browser snapshot -i -c
```

### 4. Interact with elements

Use `@ref` from the snapshot output:

```bash
agent-browser click @e5          # Click by ref
agent-browser fill @e3 "test"    # Fill input
agent-browser press Enter        # Press key
```

### 5. Compare before/after

```bash
agent-browser diff snapshot      # Compare current vs last snapshot
```

## Verification Checklist

For UI changes, verify these in order:

1. **Page loads** — no blank screen, key elements present
2. **No console errors** — `agent-browser errors` returns empty
3. **Data displays** — lists, tables, cards show expected content
4. **Forms work** — inputs accept text, selects open, buttons click
5. **Navigation works** — sidebar links lead to correct pages

## Auth Handling

If the admin requires login:

```bash
# Save auth state once
agent-browser open "http://localhost:$PORT/app/login" && \
agent-browser wait --load networkidle && \
agent-browser fill 'input[name="email"]' "admin@medusa-test.com" && \
agent-browser fill 'input[name="password"]' "supersecret" && \
agent-browser click 'button[type="submit"]' && \
agent-browser wait --load networkidle
```

For persistent sessions across commands, use `--session-name`:

```bash
agent-browser --session-name medusa-admin open "http://localhost:$PORT/app"
```

## Viewport Testing

```bash
agent-browser set viewport 375 667   # Mobile
agent-browser snapshot -i -c
agent-browser set viewport 1280 720  # Desktop (default)
```

## When to Use Screenshots

Only use screenshots for visual/layout verification (rare):

```bash
agent-browser screenshot .playwright-mcp/verify.png --full
```

For most verification tasks, snapshots are sufficient and 96% cheaper.

## Close When Done

```bash
agent-browser close
```
