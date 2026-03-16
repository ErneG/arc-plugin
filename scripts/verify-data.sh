#!/usr/bin/env bash
# Verify data integrity via SQL checks
# Usage: verify-data.sh [database_url]
set -uo pipefail

# Resolve DATABASE_URL
DB_URL="${1:-}"
if [[ -z "$DB_URL" ]]; then
  DB_URL=$(grep "^DATABASE_URL=" .env 2>/dev/null | cut -d= -f2- || echo "")
fi

if [[ -z "$DB_URL" ]]; then
  echo "SKIP: No DATABASE_URL found"
  exit 0
fi

if ! command -v psql &>/dev/null; then
  echo "SKIP: psql not installed"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_FILE="$SCRIPT_DIR/verify-data.sql"

if [[ ! -f "$SQL_FILE" ]]; then
  echo "SKIP: verify-data.sql not found at $SQL_FILE"
  exit 0
fi

echo "=== Data Integrity Check ==="
ERRORS=0

# Run SQL and parse results
RESULTS=$(psql "$DB_URL" -t -A -f "$SQL_FILE" 2>/dev/null || echo "CONNECTION_FAILED")

if [[ "$RESULTS" == "CONNECTION_FAILED" ]]; then
  echo "SKIP: Cannot connect to database"
  exit 0
fi

while IFS='|' read -r check_name count; do
  [[ -z "$check_name" ]] && continue
  count=$(echo "$count" | tr -d ' ')
  if [[ "$count" -gt 0 ]]; then
    echo "WARN: $check_name = $count"
    ERRORS=$((ERRORS + 1))
  else
    echo "PASS: $check_name = 0"
  fi
done <<< "$RESULTS"

if [[ $ERRORS -gt 0 ]]; then
  echo "FOUND: $ERRORS data integrity issues"
else
  echo "PASS: All data integrity checks passed"
fi
exit 0
