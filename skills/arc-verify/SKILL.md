---
name: arc:verify
description: >
  Run verification standalone — typecheck, tests, UX browser check.
  Triggers: "arc verify", "verify this", "check if it works".
allowed-tools: Read, Write, Bash, Grep, Glob
---

# /arc:verify — Standalone Verification

Run verification gates without advancing the pipeline. Restores original phase after.

1. Save current phase/status from STATE.json
2. Spawn **verifier** agent: typecheck → tests → agent-browser UX check
3. Show gate results
4. Restore original phase/status

Does NOT advance the pipeline. Use for checking work mid-implementation.
