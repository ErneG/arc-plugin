---
name: tide:start
description: >
  Initialize a new feature with worktree, environment setup, and state files.
  Uses Claude Code's built-in EnterWorktree tool for automatic worktree creation and cd.
  Triggers: "tide start", "start feature", "new feature".
allowed-tools: Read, Write, Bash, Grep, Glob, EnterWorktree
---

# /tide:start — Initialize Feature

## Arguments

- `<feature-name>` — required, lowercase letters/numbers/hyphens only
- `--here` — skip worktree, use current directory (for quick fixes)

## Process

1. **Validate** name: `^[a-z][a-z0-9-]*$`, max 50 chars
2. **Create worktree** (unless --here):
   Call the `EnterWorktree` tool with `name: <feature-name>`.
   This automatically:
   - Creates worktree at `.claude/worktrees/<name>/`
   - Creates branch `worktree-<name>` from HEAD
   - Switches session working directory into the worktree
   - Fires WorktreeCreate hook → .env copy + port allocation + dependency install
3. **Create state** (in the MAIN repo's .tide/ — accessible via git-common-dir):
   ```bash
   GIT_COMMON=$(git rev-parse --git-common-dir)
   MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
   mkdir -p "$MAIN_REPO/.tide/features/<name>"
   ```
4. **Initialize STATE.json** with feature name, branch, timestamp, worktree path
5. **Initialize DECISIONS.md** with feature description from user
6. **Set active feature**: `echo "<name>" > "$MAIN_REPO/.tide/active-feature"`
7. **Verify** environment:
   ```bash
   pwd                        # .claude/worktrees/<name>
   grep "^PORT=" .env         # allocated port
   git branch --show-current  # worktree-<name>
   ```

If `--here` flag: just `git checkout -b feature/<name>`, no worktree.

## Output

```
[tide] Feature '<name>' ready!
  Worktree:  .claude/worktrees/<name>
  Branch:    worktree-<name>
  Dev port:  <port>

  Next: /tide:plan <description>
```

## Resume Later

End the session normally. Next time:
```
claude --resume "tide-<name>"
```
Or from a new session, call `EnterWorktree` with the same name.

## Rules

- ALWAYS use EnterWorktree tool — never manual `git worktree add`
- The main repo stays on its current branch at all times
- State files live in main repo's `.tide/features/` (shared across worktrees)
