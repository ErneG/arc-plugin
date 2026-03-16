---
name: tide:teardown
description: >
  Clean up worktree, Neon DB branch, and feature state.
  Triggers: "tide teardown", "clean up feature", "remove worktree".
allowed-tools: Read, Bash
---

# /tide:teardown — Clean Up Feature

Uses Claude Code's built-in worktree cleanup. The WorktreeRemove hook handles
Neon branch deletion and port cleanup automatically.

## Process

1. Verify feature exists in `.tide/features/<name>/`
2. Warn if phase != "done"
3. **If in a worktree session**: ending the session triggers cleanup automatically.
   Claude Code prompts to keep or remove the worktree.
4. **If cleaning up from the main session**:
   ```bash
   git worktree remove .claude/worktrees/<name> --force
   ```
   WorktreeRemove hook fires → Neon branch deleted, port freed.
5. Delete branch if merged: `git branch -d worktree-<name>`
6. Archive state: `mv .tide/features/<name> .tide/features/_archive/<name>`
7. Clear active-feature if it matches

```
[tide] Teardown complete: <name>
  Worktree: removed
  Neon DB: deleted
  State: archived
```
