#!/bin/bash
# weekly-review.sh - Weekly productivity review with metrics
#
# Permissions granted:
#   - MCP: today-api (read todos)
#   - MCP: agentmail (send weekly report)
#
# Usage:
#   ./agents/weekly-review.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/agent-helpers.sh"

TODAY=$(date +"%A, %B %d, %Y")

log_info "Starting weekly review"

run_agent \
  --allowed-tools \
    "mcp__today-api__*" \
    "mcp__agentmail__send_message" \
    "mcp__agentmail__create_inbox" \
    "mcp__agentmail__list_inboxes" \
  --disallowed-tools \
    "Bash" \
    "Edit" \
    "Write" \
    "Read" \
  --mcp-config "$SCRIPT_DIR/../mcp-configs/todo-and-email.json" \
  --append-system-prompt-file "$SCRIPT_DIR/../prompts/weekly-review.md" \
  --max-turns 15 \
  --max-budget 1.50 \
  --model sonnet \
  --output-format text \
  "$@" \
  --prompt "Today is $TODAY. The user's email address is: ${EMAIL_TO}. Run a full weekly productivity review and email me the report."

log_ok "Weekly review complete"
