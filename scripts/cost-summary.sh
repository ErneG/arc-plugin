#!/usr/bin/env bash
# .arc/scripts/cost-summary.sh — Summarize agent costs per feature
# Usage: cost-summary.sh [feature-name]
# If no feature specified, summarizes all features.
set -euo pipefail

GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
ARC_ROOT="$MAIN_REPO/.arc"
FEATURE="${1:-}"

summarize_feature() {
  local name="$1"
  local ledger="$ARC_ROOT/features/$name/COSTS.csv"

  if [[ ! -f "$ledger" ]]; then
    echo "  No cost data for '$name'"
    return
  fi

  local total_time=0
  local total_calls=0
  local failed_calls=0

  # Skip header
  while IFS=, read -r ts feat phase dur result; do
    [[ "$ts" == "timestamp" ]] && continue
    total_time=$((total_time + dur))
    total_calls=$((total_calls + 1))
    [[ "$result" == "failed" ]] && failed_calls=$((failed_calls + 1))
  done < "$ledger"

  local minutes=$((total_time / 60))
  local seconds=$((total_time % 60))

  echo "  Feature: $name"
  echo "  Agent calls: $total_calls ($failed_calls failed)"
  echo "  Total agent time: ${minutes}m ${seconds}s"
  echo ""

  # Phase breakdown
  echo "  Phase breakdown:"
  awk -F, 'NR>1 {phase[$3]+=$4; count[$3]++} END {for (p in phase) printf "    %-20s %3d calls  %dm %ds\n", p, count[p], phase[p]/60, phase[p]%60}' "$ledger" | sort
  echo ""
}

echo "=== Arc Cost Summary ==="
echo ""

if [[ -n "$FEATURE" ]]; then
  summarize_feature "$FEATURE"
else
  for dir in "$ARC_ROOT/features"/*/; do
    [[ -d "$dir" ]] || continue
    name=$(basename "$dir")
    [[ "$name" == "_archive" ]] && continue
    summarize_feature "$name"
  done
fi
