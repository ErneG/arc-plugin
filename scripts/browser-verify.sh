#!/usr/bin/env bash
# Comprehensive browser verification using agent-browser
# Usage: browser-verify.sh [port] [page-path]
# Example: browser-verify.sh 9000 /app/manufacturers
set -uo pipefail

PORT="${1:-9000}"
PAGE="${2:-/app}"
BASE="http://localhost:$PORT"
URL="$BASE$PAGE"
ERRORS=0

# Check if agent-browser is installed
if ! command -v agent-browser &>/dev/null; then
  echo "SKIP: agent-browser not installed (npm i -g agent-browser)"
  exit 0
fi

# Check if server is running
if ! curl -sf "$BASE/health" >/dev/null 2>&1; then
  echo "SKIP: No dev server at $BASE"
  exit 0
fi

echo "=== Browser Verification: $URL ==="

# 1. Navigate and check for errors
agent-browser --profile ~/.medusa-admin open "$URL" 2>/dev/null
agent-browser wait --load networkidle 2>/dev/null

# 2. Check JS errors
JS_ERRORS=$(agent-browser errors 2>/dev/null || echo "")
if [[ -n "$JS_ERRORS" && "$JS_ERRORS" != "No errors" ]]; then
  echo "FAIL: JavaScript errors detected:"
  echo "$JS_ERRORS" | head -10
  ERRORS=$((ERRORS + 1))
else
  echo "PASS: No JavaScript errors"
fi

# 3. Check page has content (not blank)
H1_COUNT=$(agent-browser get count "h1" 2>/dev/null || echo "0")
if [[ "$H1_COUNT" == "0" ]]; then
  echo "WARN: No h1 heading found — page may be blank or loading"
else
  echo "PASS: Page has $H1_COUNT h1 heading(s)"
fi

# 4. Accessibility audit via axe-core
echo "--- Accessibility Audit ---"
AXE_RESULT=$(agent-browser eval '(async () => {
  const s = document.createElement("script");
  s.src = "https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.9.1/axe.min.js";
  document.head.appendChild(s);
  await new Promise(r => { s.onload = r; setTimeout(r, 5000); });
  if (!window.axe) return JSON.stringify({error: "axe-core failed to load"});
  const results = await axe.run();
  return JSON.stringify({
    violations: results.violations.map(v => ({id:v.id, impact:v.impact, help:v.help, nodes:v.nodes.length})),
    passes: results.passes.length
  });
})()' 2>/dev/null || echo '{"error":"eval failed"}')

if echo "$AXE_RESULT" | grep -q '"error"'; then
  echo "SKIP: axe-core could not load (offline or CSP block)"
else
  VIOLATIONS=$(echo "$AXE_RESULT" | jq -r '.violations | length' 2>/dev/null || echo "0")
  CRITICAL=$(echo "$AXE_RESULT" | jq -r '[.violations[] | select(.impact=="critical" or .impact=="serious")] | length' 2>/dev/null || echo "0")
  PASSES=$(echo "$AXE_RESULT" | jq -r '.passes' 2>/dev/null || echo "0")
  echo "  Passes: $PASSES, Violations: $VIOLATIONS (critical/serious: $CRITICAL)"
  if [[ "$CRITICAL" -gt 0 ]]; then
    echo "FAIL: $CRITICAL critical/serious a11y violations"
    echo "$AXE_RESULT" | jq -r '.violations[] | select(.impact=="critical" or .impact=="serious") | "  - \(.id): \(.help) (\(.nodes) elements)"' 2>/dev/null
    ERRORS=$((ERRORS + 1))
  else
    echo "PASS: No critical accessibility violations"
  fi
fi

# 5. Heading hierarchy check
echo "--- Heading Hierarchy ---"
HEADINGS=$(agent-browser eval 'JSON.stringify(Array.from(document.querySelectorAll("h1,h2,h3,h4,h5,h6")).map(h => ({
  tag:h.tagName, text:h.textContent?.trim().slice(0,50), fontSize:getComputedStyle(h).fontSize
})))' 2>/dev/null || echo "[]")

H1S=$(echo "$HEADINGS" | jq '[.[] | select(.tag=="H1")] | length' 2>/dev/null || echo "0")
if [[ "$H1S" -gt 1 ]]; then
  echo "WARN: $H1S h1 headings found — should be exactly 1"
elif [[ "$H1S" -eq 0 ]]; then
  echo "WARN: No h1 heading — every page needs a title"
else
  echo "PASS: Exactly 1 h1 heading"
fi

# 6. Empty state detection
echo "--- Empty/Loading States ---"
STATES=$(agent-browser eval 'JSON.stringify({
  emptyStates: document.querySelectorAll("[class*=empty],[class*=no-data],[class*=no-results]").length,
  skeletons: document.querySelectorAll("[class*=skeleton],[role=progressbar]").length,
  emptyTables: document.querySelectorAll("table tbody:empty").length
})' 2>/dev/null || echo '{}')
echo "  $(echo "$STATES" | jq -r 'to_entries | map("\(.key): \(.value)") | join(", ")' 2>/dev/null || echo "$STATES")"

# 7. Button audit
echo "--- Button Hierarchy ---"
BUTTONS=$(agent-browser eval 'JSON.stringify({
  total: document.querySelectorAll("button,[role=button]").length,
  primary: document.querySelectorAll("button[class*=primary],[button class*=btn-primary]").length,
  disabled: document.querySelectorAll("button:disabled,[role=button][aria-disabled=true]").length
})' 2>/dev/null || echo '{}')
echo "  $(echo "$BUTTONS" | jq -r 'to_entries | map("\(.key): \(.value)") | join(", ")' 2>/dev/null || echo "$BUTTONS")"

# 8. Interactive snapshot (low token)
echo "--- Interactive Elements ---"
agent-browser snapshot -i -c 2>/dev/null | head -30

# Cleanup
agent-browser close 2>/dev/null

echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "RESULT: $ERRORS failures found"
else
  echo "RESULT: All checks passed"
fi
exit $ERRORS
