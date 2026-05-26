#!/bin/bash
# enforce-builtin-tools.sh — PreToolUse hook for Claude Code
# Intercepts Bash commands that should use dedicated tools (Read, Glob, Grep, Edit, Write)
# and denies them with a pointer to the correct tool.

# **IMPORTANT NOTE** THIS HAS BEEN REMOVED FROM DEFAULT SETTINGS DUE TO AMOUNT OF FRICTION IT CAUSES.
#                    Claude Code is not reliable in choosing to use its own tools, and new Claude
#                    releases are not reliable in having consistent set of tools available.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# Deny "cd dir && command" patterns; use absolute paths or cwd parameter instead
if echo "$COMMAND" | grep -qE '^\s*(cd|pushd)\s+\S+\s*(&&|;|\|\|)'; then
  REAL_CMD=$(echo "$COMMAND" | sed -E 's/^\s*(cd|pushd)\s+("[^"]*"|'\''[^'\'']*'\''|[^ &;|]+)\s*(&&|;|\|\|)\s*//')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Do not prefix with cd. Run directly: $REAL_CMD\"}}"
  exit 0
fi

# Check each segment of piped/chained commands
while IFS= read -r segment; do
  # Strip leading whitespace and env var assignments
  cmd=$(echo "$segment" | sed 's/^[[:space:]]*//' | sed 's/^[A-Za-z_][A-Za-z_0-9]*=[^ ]* //')
  # Get the base command name
  base=$(basename "$(echo "$cmd" | awk '{print $1}')" 2>/dev/null)

  case "$base" in
    cat)       msg="Use the Read tool to read files, or Write to create them." ;;
    head|tail) msg="Use the Read tool with offset and limit parameters." ;;
    sed)       msg="Use the Edit tool for modifications, or Read for extracting line ranges." ;;
    grep|rg)   msg="Use the built-in Grep tool." ;;
    find)      msg="Use the built-in Glob tool." ;;
    ls)        msg="Use the built-in Glob tool, or Read for file contents." ;;
    for|while) msg="Use the Glob tool to list files, or Read to read them." ;;
    *)         continue ;;
  esac

  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Do not use \`$base\` via Bash. $msg\"}}"
  exit 0
done < <(echo "$COMMAND" | tr '|' '\n' | sed 's/[;&]\{1,2\}/\n/g')

exit 0
