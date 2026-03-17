---
name: tide:metrics
description: >
  Show development metrics: rework rate, active features.
  Triggers: "tide metrics", "show metrics", "rework rate".
allowed-tools: Bash, Read
---

# /tide:metrics — Development Observability

```bash
# Rework rate (DORA 5th metric)
bash "${CLAUDE_PLUGIN_ROOT}/scripts/track-rework.sh" 14

# Active features
for f in .tide/features/*/STATE.json; do
  name=$(basename "$(dirname "$f")")
  phase=$(jq -r '.phase' "$f")
  task=$(jq -r '"\(.task.current)/\(.task.total)"' "$f")
  echo "  $name: $phase (task $task)"
done
```
