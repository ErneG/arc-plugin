---
name: arc:metrics
description: >
  Show development metrics: rework rate, cost per feature, agent stats.
  Triggers: "arc metrics", "show metrics", "rework rate", "how much did this cost".
allowed-tools: Bash, Read
---

# /arc:metrics — Development Observability

```bash
# Rework rate (DORA 5th metric)
bash "${CLAUDE_PLUGIN_ROOT}/scripts/track-rework.sh" 14

# Cost summary
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cost-summary.sh"

# Active features
for f in .arc/features/*/STATE.json; do
  name=$(basename "$(dirname "$f")")
  phase=$(jq -r '.phase' "$f")
  echo "  $name: $phase"
done
```
