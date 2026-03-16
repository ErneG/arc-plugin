---
name: arc:deploy
description: >
  Merge PR, deploy to Coolify, verify health. Triggers: "arc deploy", "merge and deploy".
allowed-tools: Read, Write, Bash
---

# /arc:deploy — Merge and Deploy

1. Verify PR is mergeable (checks passing, reviews approved)
2. Merge PR: `gh pr merge <number> --merge`
3. Deploy via Coolify MCP or API
4. Wait for deployment, check health endpoint
5. Update STATE.json with deploy status
6. Set phase to "done"

Requires `deploy.app_uuid` and `deploy.health_url` in `.arc/config.json`.

```
[arc] Deployed! Health check passed.
  Next: /arc:teardown <name> to clean up
```
