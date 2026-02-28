#!/bin/bash
# custom-task.sh - Run an ad-hoc agent with a custom prompt
#
# A general-purpose agent runner for one-off tasks.
# You specify permissions via flags and pass a free-form prompt.
#
# Usage:
#   ./agents/custom-task.sh --web --email "Research X and email me a summary"
#   ./agents/custom-task.sh --todo "Create tasks for the Q1 roadmap"
#   ./agents/custom-task.sh --files --git "Review code in ./src for security issues"

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/agent-helpers.sh"

# Parse capability flags
TOOLS=()
DISALLOWED=("Edit" "Write")  # Safe defaults: no writes
MCP_CONFIG=""
PROMPT=""

show_help() {
  cat <<'EOF'
Usage: custom-task.sh [capabilities] "prompt"

Capabilities:
  --web        Enable web search
  --todo       Enable Today API (read/write todos)
  --email      Enable sending emails (requires --todo)
  --files      Enable reading local files
  --git        Enable read-only git commands
  --edit       Enable editing files (careful!)
  --all        Enable all capabilities

Example:
  ./agents/custom-task.sh --web --todo "Find best practices for GTD and create tasks"
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --web)
      TOOLS+=("WebSearch" "WebFetch")
      shift ;;
    --todo)
      TOOLS+=("mcp__today-api__*")
      MCP_CONFIG="$SCRIPT_DIR/../mcp-configs/readonly.json"
      shift ;;
    --email)
      TOOLS+=("mcp__agentmail__send_message" "mcp__agentmail__create_inbox" "mcp__agentmail__list_inboxes")
      MCP_CONFIG="$SCRIPT_DIR/../mcp-configs/todo-and-email.json"
      shift ;;
    --files)
      TOOLS+=("Read" "Glob" "Grep")
      shift ;;
    --git)
      TOOLS+=("Bash(git log *)" "Bash(git diff *)" "Bash(git show *)" "Bash(git status)")
      shift ;;
    --edit)
      DISALLOWED=()  # Remove Edit/Write from disallowed
      TOOLS+=("Edit" "Write" "Read" "Glob" "Grep")
      shift ;;
    --all)
      TOOLS+=("WebSearch" "WebFetch" "Read" "Glob" "Grep" "Edit" "Write"
              "Bash(git *)" "mcp__today-api__*"
              "mcp__agentmail__send_message" "mcp__agentmail__create_inbox" "mcp__agentmail__list_inboxes")
      DISALLOWED=()
      MCP_CONFIG="$SCRIPT_DIR/../mcp-configs/todo-and-email.json"
      shift ;;
    --help|-h)
      show_help ;;
    --dry-run|--verbose)
      # Pass through to run_agent
      break ;;
    *)
      PROMPT="$1"
      shift ;;
  esac
done

if [ -z "$PROMPT" ]; then
  log_error "No prompt provided. Usage: custom-task.sh [capabilities] \"prompt\""
  exit 1
fi

AGENT_ARGS=(
  --allowed-tools "${TOOLS[@]}"
)

if [ ${#DISALLOWED[@]} -gt 0 ]; then
  AGENT_ARGS+=(--disallowed-tools "${DISALLOWED[@]}")
fi

if [ -n "$MCP_CONFIG" ]; then
  AGENT_ARGS+=(--mcp-config "$MCP_CONFIG")
fi

run_agent \
  "${AGENT_ARGS[@]}" \
  --max-turns 10 \
  --max-budget 0.50 \
  --model sonnet \
  --output-format text \
  "$@" \
  --prompt "$PROMPT"
