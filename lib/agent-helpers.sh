#!/bin/bash
# agent-helpers.sh - Common utilities for agent scripts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
  set -a
  source "$PROJECT_ROOT/.env"
  set +a
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Build --allowedTools string from an array
build_allowed_tools() {
  local tools=("$@")
  local result=""
  for tool in "${tools[@]}"; do
    if [ -n "$result" ]; then
      result="$result \"$tool\""
    else
      result="\"$tool\""
    fi
  done
  echo "$result"
}

# Main agent runner
# Usage: run_agent [options] --prompt "task description"
run_agent() {
  local allowed_tools=()
  local disallowed_tools=()
  local mcp_config=""
  local system_prompt=""
  local system_prompt_file=""
  local append_system_prompt=""
  local append_system_prompt_file=""
  local max_turns=""
  local max_budget=""
  local output_format="text"
  local prompt=""
  local model=""
  local dry_run=false
  local verbose=false
  local json_schema=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      --allowed-tools)
        shift
        while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
          allowed_tools+=("$1")
          shift
        done
        ;;
      --disallowed-tools)
        shift
        while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
          disallowed_tools+=("$1")
          shift
        done
        ;;
      --mcp-config)
        mcp_config="$2"; shift 2 ;;
      --system-prompt)
        system_prompt="$2"; shift 2 ;;
      --system-prompt-file)
        system_prompt_file="$2"; shift 2 ;;
      --append-system-prompt)
        append_system_prompt="$2"; shift 2 ;;
      --append-system-prompt-file)
        append_system_prompt_file="$2"; shift 2 ;;
      --max-turns)
        max_turns="$2"; shift 2 ;;
      --max-budget)
        max_budget="$2"; shift 2 ;;
      --output-format)
        output_format="$2"; shift 2 ;;
      --model)
        model="$2"; shift 2 ;;
      --prompt)
        prompt="$2"; shift 2 ;;
      --dry-run)
        dry_run=true; shift ;;
      --verbose)
        verbose=true; shift ;;
      --json-schema)
        json_schema="$2"; shift 2 ;;
      *)
        log_error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  if [ -z "$prompt" ]; then
    log_error "No --prompt provided"
    return 1
  fi

  # Build the claude command
  local cmd="claude -p"

  # Permission mode: deny everything not explicitly allowed
  cmd+=" --permission-mode dontAsk"

  # Allowed tools
  for tool in "${allowed_tools[@]}"; do
    cmd+=" --allowedTools \"$tool\""
  done

  # Disallowed tools
  for tool in "${disallowed_tools[@]}"; do
    cmd+=" --disallowedTools \"$tool\""
  done

  # MCP config
  if [ -n "$mcp_config" ]; then
    cmd+=" --mcp-config \"$mcp_config\""
  fi

  # System prompt
  if [ -n "$system_prompt" ]; then
    cmd+=" --system-prompt \"$system_prompt\""
  elif [ -n "$system_prompt_file" ]; then
    cmd+=" --system-prompt-file \"$system_prompt_file\""
  fi

  # Append system prompt
  if [ -n "$append_system_prompt" ]; then
    cmd+=" --append-system-prompt \"$append_system_prompt\""
  elif [ -n "$append_system_prompt_file" ]; then
    cmd+=" --append-system-prompt-file \"$append_system_prompt_file\""
  fi

  # Limits
  if [ -n "$max_turns" ]; then
    cmd+=" --max-turns $max_turns"
  fi
  if [ -n "$max_budget" ]; then
    cmd+=" --max-budget-usd $max_budget"
  fi

  # Model
  if [ -n "$model" ]; then
    cmd+=" --model $model"
  fi

  # Output format
  cmd+=" --output-format $output_format"

  # JSON schema
  if [ -n "$json_schema" ]; then
    cmd+=" --json-schema '$json_schema'"
  fi

  # The prompt itself (always last)
  cmd+=" \"$prompt\""

  # Dry run - just show the command
  if [ "$dry_run" = true ]; then
    log_info "DRY RUN - would execute:"
    echo ""
    echo "$cmd"
    echo ""
    return 0
  fi

  # Execute
  log_info "Running agent..."
  if [ "$verbose" = true ]; then
    log_info "Command: $cmd"
  fi

  eval "$cmd"
}
