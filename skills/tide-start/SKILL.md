---
name: tide:start
description: >
  Initialize a new feature with worktree, Neon DB branch, and state files.
  Uses Claude Code's built-in worktree system — automatic cd, session naming, cleanup.
  Triggers: "tide start", "start feature", "new feature".
allowed-tools: Read, Write, Bash, Grep, Glob
---

# /tide:start — Initialize Feature

Uses Claude Code's BUILT-IN worktree system. Do NOT manually run `git worktree add`.

## Arguments

- `<feature-name>` — required, lowercase letters/numbers/hyphens only
- `--here` — skip worktree, use current directory (for quick fixes)

## Process

### If in the MAIN session (not yet in a worktree):

1. **Validate** name: `^[a-z][a-z0-9-]*$`, max 50 chars
2. **Tell the user** to start a new Claude Code session with the worktree flag:

   ```
   Run this in a new terminal:
   claude --worktree <name> -n "tide-<name>"
   ```

   This automatically:
   - Creates worktree at `.claude/worktrees/<name>/`
   - Creates branch `worktree-<name>`
   - cd's into the worktree (automatic, no manual cd needed)
   - Names the session for later resume (`claude --resume "tide-<name>"`)
   - Fires the WorktreeCreate hook → Neon DB branch + .env + port + yarn install

3. **Create state** (in the MAIN repo, accessible from worktree):
   ```bash
   mkdir -p .tide/features/<name>
   ```
4. **Initialize STATE.json** from template with feature name, branch, timestamp
5. **Initialize DECISIONS.md** with feature description from user
6. **Set active feature**: `echo "<name>" > .tide/active-feature`

### If ALREADY in a worktree session (user ran `claude --worktree`):

The WorktreeCreate hook has already provisioned everything. Just:

1. **Create state**: `mkdir -p .tide/features/<name>`
2. **Initialize STATE.json and DECISIONS.md**
3. **Set active feature**
4. **Verify environment**:
   ```bash
   pwd                           # Should be in .claude/worktrees/<name>
   grep "^PORT=" .env            # Should show allocated port
   git branch --show-current     # Should be worktree-<name>
   ```

### If --here flag (no worktree):

1. Create branch: `git checkout -b feature/<name>`
2. Initialize state files
3. No Neon branch, no port allocation, no env patching

## Output

```
[tide] Feature '<name>' ready!
  Worktree:  .claude/worktrees/<name>
  Branch:    worktree-<name>
  Neon DB:   wt/<name>
  Dev port:  <port>
  Session:   tide-<name> (resume with: claude --resume "tide-<name>")

  Next: /tide:plan <description>
```

## Rules

- Use Claude Code's built-in `--worktree` flag — NEVER manual `git worktree add`
- The main repo stays on master at all times
- Each feature = separate terminal with `claude --worktree <name>`
- Resume with `claude --resume "tide-<name>"`
- Cleanup is automatic when session ends with no changes
