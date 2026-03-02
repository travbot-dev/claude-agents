#!/bin/bash
# daily-planner.sh - Review todos, give feedback, plan tomorrow, send email
#
# Permissions granted:
#   - WebSearch (for context on tasks if needed)
#   - Bash: curl (for Today REST API calls)
#   - MCP: agentmail (send daily summary email)
#
# Permissions denied:
#   - File read/write (not needed)
#   - Bash: anything besides curl
#
# Usage:
#   ./agents/daily-planner.sh              # Run normally
#   ./agents/daily-planner.sh --dry-run    # Show command without running
#   ./agents/daily-planner.sh --verbose    # Show full output

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/agent-helpers.sh"

TODAY=$(date +"%A, %B %d, %Y")

WEEK_REVIEWS_DIR="$SCRIPT_DIR/../data/week-reviews"
WEEK_REVIEW_CONTEXT=""
if [ -d "$WEEK_REVIEWS_DIR" ] && ls "$WEEK_REVIEWS_DIR"/*.md &>/dev/null; then
  while IFS= read -r f; do
    WEEK_REVIEW_CONTEXT+="
--- $(basename "$f") ---
$(cat "$f")
"
  done < <(ls "$WEEK_REVIEWS_DIR"/*.md | sort | tail -4)
fi

log_info "Starting daily planner for $TODAY"

run_agent \
  --allowed-tools \
    "WebSearch" \
    "Bash(curl *today.travserve.net*)" \
    "mcp__agentmail__send_message" \
    "mcp__agentmail__create_inbox" \
    "mcp__agentmail__list_inboxes" \
  --disallowed-tools \
    "Edit" \
    "Write" \
    "Read" \
  --mcp-config "$SCRIPT_DIR/../mcp-configs/email-only.json" \
  --append-system-prompt-file "$SCRIPT_DIR/../prompts/daily-planner.md" \
  --max-turns 15 \
  --max-budget 1.00 \
  --model sonnet \
  --output-format text \
  "$@" \
  --prompt "Today is $TODAY.
The user email address is: ${EMAIL_TO}
Today API base URL: ${TODAY_API_URL}
Today API auth token: ${TODAY_API_TOKEN}

Here are my recent week reviews for additional context on priorities, reflections, and patterns:
${WEEK_REVIEW_CONTEXT:-No week reviews found.}

Review my todo activity from the past week, give me honest feedback on my productivity patterns, plan my day for today, and email me the summary. Use my week reviews as context to inform your analysis and recommendations.

Do this now - pull the data, analyze it, write the plan, and send the email."

log_ok "Daily planner complete"
