---
name: tide:verify
description: >
  Run verification — typecheck, lint, tests, browser.
  Sub-commands: lint, browser, all (default).
  Triggers: "tide verify", "verify this", "check if it works", "run checks".
allowed-tools: Read, Write, Bash, Grep, Glob
---

# /tide:verify — Verification Suite

Runs verification gates. Default runs all gates. Sub-commands run specific ones.

## Sub-commands

- `/tide:verify` or `/tide:verify all` — run all gates in order
- `/tide:verify browser [page]` — agent-browser verification (a11y, hierarchy, states)

## Full Verification Order

1. **Typecheck**: `npx tsc --noEmit` (if tsconfig.json exists)
2. **Lint**: detect and run project's linter (eslint, biome, etc.)
3. **Tests**: detect and run project's test suite
4. **Browser**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/browser-verify.sh" $PORT $PAGE`

## Standalone Mode

When run standalone (not as part of /tide:go), saves current phase and
restores it after verification. Does NOT advance the pipeline.
