---
name: tide:fix
description: >
  Quick fix path — no worktree, no plan, no research. For typos, config changes,
  one-off fixes. Auto-ships on pass.
  Triggers: "tide fix", "quick fix", "hotfix".
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# /tide:fix — Quick Fix

For small changes that don't need the full pipeline.

1. Create branch: `git checkout -b fix/<description>`
2. Make the fix
3. Run `npx tsc --noEmit`
4. Commit
5. Push and create PR: `gh pr create`

No worktree, no Neon branch, no plan, no review cycle.
Use for: typos, config changes, dependency bumps, one-line bug fixes.
