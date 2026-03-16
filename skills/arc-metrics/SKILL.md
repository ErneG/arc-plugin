---
name: arc:metrics
description: >
  Show development metrics: rework rate, active features.
  Triggers: "arc metrics", "show metrics", "rework rate".
allowed-tools: Bash, Read
---

# /arc:metrics — Development Observability

```bash
# Rework rate (DORA 5th metric)
bash "${CLAUDE_PLUGIN_ROOT}/scripts/track-rework.sh" 14

# Active features
for f in .arc/features/*/STATE.json; do
  name=$(basename "$(dirname "$f")")
  phase=$(jq -r '.phase' "$f")
  task=$(jq -r '"\(.task.current)/\(.task.total)"' "$f")
  echo "  $name: $phase (task $task)"
done
```
