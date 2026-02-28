#!/bin/bash
# code-digest.sh - Summarize recent git activity and create task items
#
# This agent reviews your git commits from the past week,
# identifies any loose ends (TODOs, FIXMEs, incomplete work),
# and creates follow-up tasks in your todo app.
#
# Permissions granted:
#   - Bash: git log, git diff, git show (read-only git)
#   - Read: source files (for context on changes)
#   - MCP: today-api (create follow-up todos)
#
# Permissions denied:
#   - Edit, Write (no modifications to code)
#   - Bash: anything besides git

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/agent-helpers.sh"

REPO_DIR="${1:-.}"
log_info "Reviewing git activity in $REPO_DIR"

run_agent \
  --allowed-tools \
    "Bash(git log *)" \
    "Bash(git diff *)" \
    "Bash(git show *)" \
    "Bash(git shortlog *)" \
    "Read" \
    "Grep" \
    "Glob" \
    "mcp__today-api__*" \
  --disallowed-tools \
    "Edit" \
    "Write" \
  --mcp-config "$SCRIPT_DIR/../mcp-configs/readonly.json" \
  --max-turns 20 \
  --max-budget 1.00 \
  --model sonnet \
  --output-format text \
  --prompt "Review the git history in $REPO_DIR from the past 7 days.

1. Summarize what was worked on (group by feature/area)
2. Find any TODO, FIXME, HACK, or XXX comments in recently changed files
3. Identify any incomplete work (partial implementations, commented-out code)
4. Create follow-up tasks in the todo app for anything that needs attention

Be concise. Focus on actionable items."

log_ok "Code digest complete"
