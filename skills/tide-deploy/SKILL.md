---
name: tide:deploy
description: >
  Merge PR and monitor deployment. Coolify CI/CD handles the actual deploy automatically.
  Triggers: "tide deploy", "merge and deploy", "land it".
allowed-tools: Read, Bash
---

# /tide:deploy — Merge PR

Coolify auto-deploys on merge. This skill just merges and monitors.

## Process

1. Verify PR is mergeable: `gh pr checks <number>`
2. Merge PR: `gh pr merge <number> --merge`
3. Monitor Coolify deployment (auto-triggered by push to master):
   ```bash
   # Wait for deploy, then check health
   sleep 30
   curl -sf <health_url> > /dev/null && echo "Healthy" || echo "Check deployment"
   ```
4. Update STATE.json: phase → "done"

No manual deploy trigger needed — Coolify watches the repo.
