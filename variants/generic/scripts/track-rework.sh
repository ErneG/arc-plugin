#!/usr/bin/env bash
# .tide/scripts/track-rework.sh — Track code rework rate (DORA 5th metric)
# Detects files changed by AI that were modified again within 14 days.
# Usage: track-rework.sh [days=14]
# Outputs a report of reworked files with their original and rework commits.
set -euo pipefail

DAYS="${1:-14}"
CUTOFF_DATE=$(date -v-${DAYS}d +"%Y-%m-%d" 2>/dev/null || date -d "-${DAYS} days" +"%Y-%m-%d")
GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")
MAIN_REPO=$(cd "$(dirname "$GIT_COMMON")" && pwd)
TIDE_ROOT="$MAIN_REPO/.tide"
REPORT="$TIDE_ROOT/metrics/rework-report.md"

mkdir -p "$TIDE_ROOT/metrics"

# Get all commits in the window
COMMITS=$(git log --since="$CUTOFF_DATE" --format="%H %aI %s" --no-merges -- src/ 2>/dev/null || echo "")

if [[ -z "$COMMITS" ]]; then
  echo "No commits in the last $DAYS days."
  exit 0
fi

# Build a map of file → first commit in window → subsequent commits
declare -A FILE_FIRST_COMMIT
declare -A FILE_REWORK_COUNT
declare -A FILE_COMMITS

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  HASH=$(echo "$line" | cut -d' ' -f1)
  FILES=$(git diff-tree --no-commit-id --name-only -r "$HASH" -- src/ 2>/dev/null || true)

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    if [[ -z "${FILE_FIRST_COMMIT[$file]:-}" ]]; then
      FILE_FIRST_COMMIT[$file]="$HASH"
      FILE_REWORK_COUNT[$file]=0
      FILE_COMMITS[$file]="$HASH"
    else
      FILE_REWORK_COUNT[$file]=$(( ${FILE_REWORK_COUNT[$file]} + 1 ))
      FILE_COMMITS[$file]="${FILE_COMMITS[$file]} $HASH"
    fi
  done <<< "$FILES"
done <<< "$COMMITS"

# Calculate metrics
TOTAL_FILES=${#FILE_FIRST_COMMIT[@]}
REWORKED_FILES=0
REWORKED_LIST=""

for file in "${!FILE_REWORK_COUNT[@]}"; do
  if [[ ${FILE_REWORK_COUNT[$file]} -gt 0 ]]; then
    REWORKED_FILES=$((REWORKED_FILES + 1))
    REWORKED_LIST="${REWORKED_LIST}\n- **${file}** (${FILE_REWORK_COUNT[$file]} rework commits)"
  fi
done

if [[ $TOTAL_FILES -gt 0 ]]; then
  REWORK_RATE=$(( (REWORKED_FILES * 100) / TOTAL_FILES ))
else
  REWORK_RATE=0
fi

# Write report
cat > "$REPORT" <<REPORT
# Rework Rate Report

**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Window**: Last $DAYS days (since $CUTOFF_DATE)

## Summary

| Metric | Value |
|--------|-------|
| Files touched | $TOTAL_FILES |
| Files reworked | $REWORKED_FILES |
| **Rework rate** | **${REWORK_RATE}%** |

## Reworked Files
$(echo -e "$REWORKED_LIST" | sort || echo "None — all code stuck on first attempt.")

## Interpretation

- **< 10%**: Healthy. AI code is sticking.
- **10-25%**: Monitor. Some churn, may need better planning.
- **> 25%**: Action needed. AI is producing throwaway code.

DORA's 5th metric considers < 15% rework rate as "elite" performance.
REPORT

echo "Rework rate: ${REWORK_RATE}% ($REWORKED_FILES / $TOTAL_FILES files)"
echo "Report: $REPORT"
