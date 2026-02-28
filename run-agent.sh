#!/bin/bash
# run-agent.sh - Universal agent runner
#
# Usage:
#   ./run-agent.sh <agent-name> [flags]
#
# Examples:
#   ./run-agent.sh daily-planner
#   ./run-agent.sh daily-planner --dry-run
#   ./run-agent.sh weekly-review --verbose
#   ./run-agent.sh code-digest /path/to/repo

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <agent-name> [args...]"
  echo ""
  echo "Available agents:"
  for f in "$SCRIPT_DIR/agents/"*.sh; do
    name=$(basename "$f" .sh)
    # Extract the comment after the filename
    desc=$(head -2 "$f" | tail -1 | sed 's/^# //')
    printf "  %-20s %s\n" "$name" "$desc"
  done
  exit 1
fi

AGENT_NAME="$1"
shift

AGENT_SCRIPT="$SCRIPT_DIR/agents/$AGENT_NAME.sh"

if [ ! -f "$AGENT_SCRIPT" ]; then
  echo "Error: Agent '$AGENT_NAME' not found at $AGENT_SCRIPT"
  exit 1
fi

exec bash "$AGENT_SCRIPT" "$@"
