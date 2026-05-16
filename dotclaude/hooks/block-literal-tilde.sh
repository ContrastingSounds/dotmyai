#!/bin/bash
# block-literal-tilde.sh — PreToolUse hook for Claude Code
# Blocks Write/Edit calls where the file_path contains a literal ~/
# (unexpanded tilde), which creates junk directories inside the project.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0

if echo "$FILE_PATH" | grep -qE '(^|/)\~/'; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Path contains a literal '~' directory. Use the fully expanded absolute path (e.g. /Users/jon/...) instead of ~/.\"}}"
  exit 0
fi

exit 0
