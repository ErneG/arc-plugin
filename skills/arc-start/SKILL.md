---
name: arc:start
description: >
  Initialize a new feature with worktree, Neon DB branch, and state files.
  Triggers: "arc start", "start feature", "new feature".
allowed-tools: Read, Write, Bash, Grep, Glob
---

# /arc:start — Initialize Feature

## Arguments

- `<feature-name>` — required, lowercase letters/numbers/hyphens only
- `--here` — skip worktree, use current directory

## Process

1. **Validate** name: `^[a-z][a-z0-9-]*$`, max 50 chars
2. **Create worktree** (unless --here):
   ```bash
   git worktree add .arc/worktrees/<name> -b feature/<name>
   ```
   WorktreeCreate hook fires automatically: Neon branch + .env + yarn install + port
3. **Create state**: `mkdir -p .arc/features/<name>`
4. **Initialize STATE.json** from template with feature name, branch, timestamp
5. **Initialize DECISIONS.md** with feature description from user
6. **Set active feature**: `echo "<name>" > .arc/active-feature`
7. **Read port** from `.arc/worktree-ports` manifest

## Output

```
[arc] Feature '<name>' ready!
  Worktree:  .arc/worktrees/<name>
  Neon DB:   wt/<name>
  Dev port:  <port>

  Next: /arc:plan <description>
```
