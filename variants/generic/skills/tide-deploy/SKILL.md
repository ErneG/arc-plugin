---
name: tide:deploy
description: >
  Merge PR and monitor deployment. Works with any CI/CD that auto-deploys on merge.
  Triggers: "tide deploy", "merge and deploy", "land it".
allowed-tools: Read, Bash
---

# /tide:deploy — Merge PR

Merges the PR. Your CI/CD auto-deploys on merge (configure in .tide/config.json).

## Process

1. Verify PR is mergeable: `gh pr checks <number>`
2. Merge PR: `gh pr merge <number> --merge`
3. Monitor deployment:
   ```bash
   HEALTH_URL=$(jq -r '.deploy.health_url // empty' .tide/config.json 2>/dev/null)
   if [[ -n "$HEALTH_URL" ]]; then
     sleep 30
     curl -sf "$HEALTH_URL" > /dev/null && echo "Healthy" || echo "Check deployment"
   else
     echo "No health_url configured — verify deployment manually"
   fi
   ```
4. Update STATE.json: phase → "done"
