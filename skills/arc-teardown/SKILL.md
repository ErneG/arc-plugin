---
name: arc:teardown
description: >
  Clean up worktree, Neon DB branch, and feature state.
  Triggers: "arc teardown", "clean up feature", "remove worktree".
allowed-tools: Read, Bash
---

# /arc:teardown — Clean Up Feature

1. Verify feature exists in `.arc/features/<name>/`
2. Warn if phase != "done"
3. Remove worktree: `git worktree remove .arc/worktrees/<name> --force`
   (WorktreeRemove hook handles Neon branch deletion + port cleanup)
4. Delete branch if merged: `git branch -d feature/<name>`
5. Archive state: `mv .arc/features/<name> .arc/features/_archive/<name>`
6. Clear active-feature if it matches

```
[arc] Teardown complete: <name>
  Worktree: removed
  Neon DB: deleted
  State: archived
```
