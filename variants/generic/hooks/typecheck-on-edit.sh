#!/bin/bash
# Hook: PostToolUse — run tsc after TS/TSX edits (informational, not blocking)
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null)
[[ -z "$FILE_PATH" ]] && exit 0
echo "$FILE_PATH" | grep -qE '\.(ts|tsx)$' || exit 0
echo "$FILE_PATH" | grep -qE '(\.d\.ts$|node_modules/)' && exit 0
OUTPUT=$(npx tsc --noEmit --incremental 2>&1 | head -30)
if [[ $? -ne 0 ]]; then
  echo "Type errors after editing $FILE_PATH:"
  echo "$OUTPUT"
fi
exit 0
