---
name: arc:status
description: >
  Show progress for active or specified feature.
  Triggers: "arc status", "where am i", "feature status".
allowed-tools: Read, Bash
---

# /arc:status — Feature Status

Show current state of the active feature (or all features).

1. Read `.arc/active-feature` (or argument)
2. Read STATE.json: phase, task progress, gates
3. Read PROGRESS.md if it exists
4. Show worktree ports from `.arc/worktree-ports`
5. List all active features if no argument given

```
Feature: translations
Phase:   implement (task 3/5)
Branch:  feature/translations
Port:    9187
Gates:   typecheck=true tests=false browser=skipped
```
