---
name: tide:ship
description: >
  Push branch, create PR with metrics. Triggers: "tide ship", "create pr", "push and pr".
allowed-tools: Read, Write, Bash
---

# /tide:ship — Push and Create PR

1. Check STATE.json: verify phase is "review" with status "complete"
2. Push branch: `git push -u origin <branch>`
3. Create PR with `gh pr create` including:
   - Summary from PLAN.md goal
   - Key decisions from DECISIONS.md
   - Acceptance criteria from PLAN.md
   - Gate results (typecheck, tests, browser, review)
4. Post metrics comment (cost summary + rework rate)
5. Update STATE.json with PR number and URL
6. Set phase to "post-pr"

```
[tide] PR #N created: <url>
  Next: Wait for CI + review, then /tide:deploy
```
