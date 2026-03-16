---
name: tide:verify
description: >
  Run verification — modules, routes, typecheck, tests, browser, data.
  Sub-commands: modules, routes, browser, data, all (default).
  Triggers: "tide verify", "verify this", "check if it works", "run checks".
allowed-tools: Read, Write, Bash, Grep, Glob
---

# /tide:verify — Verification Suite

Runs verification gates. Default runs all gates. Sub-commands run specific ones.

## Sub-commands

- `/tide:verify` or `/tide:verify all` — run all gates in order
- `/tide:verify modules` — module integrity only (MODULE_NAMES vs config vs disk)
- `/tide:verify routes` — route validation only (zod schemas + middleware)
- `/tide:verify browser [page]` — agent-browser verification (a11y, hierarchy, states)
- `/tide:verify data` — data integrity SQL checks (needs psql + DATABASE_URL)

## Full Verification Order

1. **Modules**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/verify-modules.sh"`
2. **Routes**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/verify-routes.sh"`
3. **Typecheck**: `npx tsc --noEmit`
4. **Tests**: `yarn test:integration:modules` / `yarn test:integration:http`
5. **Browser**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/browser-verify.sh" $PORT $PAGE`
6. **Data**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/verify-data.sh"`

## Standalone Mode

When run standalone (not as part of /tide:go), saves current phase and
restores it after verification. Does NOT advance the pipeline.
