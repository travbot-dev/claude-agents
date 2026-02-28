# Claude Agents Framework

A framework for running agentic tasks via `claude -p` with controlled permissions, MCP integrations, and composable skills.

## Architecture

```
claude-agents/
├── agents/              # Executable agent scripts (one command = one task)
│   ├── daily-planner.sh # Review todos, give feedback, plan tomorrow, email summary
│   ├── inbox-zero.sh    # Process and triage emails
│   └── weekly-review.sh # Weekly productivity review
├── skills/              # Reusable SKILL.md files for Claude
├── mcp-configs/         # MCP server configs for external API access
├── prompts/             # System prompt fragments (composable)
└── run-agent.sh         # Universal agent runner with permission enforcement
```

## Quick Start

```bash
# 1. Configure your API keys
cp .env.example .env
# Edit .env with your keys

# 2. Run an agent
./run-agent.sh daily-planner

# 3. Run with explicit permissions
./run-agent.sh daily-planner --dry-run   # Preview what it would do
./run-agent.sh daily-planner --verbose   # See full output
```

## How It Works

Each agent is a self-contained script that:

1. Declares its **permissions** (which tools it can use)
2. Loads its **MCP servers** (external APIs it needs)
3. Composes a **system prompt** (personality + task instructions)
4. Runs `claude -p` with all of the above wired together

Permissions follow the principle of least privilege - each agent only
gets access to what it needs to complete its task.

## Creating a New Agent

See `agents/daily-planner.sh` as a reference. The pattern is:

```bash
#!/bin/bash
source "$(dirname "$0")/../lib/agent-helpers.sh"

ALLOWED_TOOLS=(
  "Read"
  "WebSearch"
  "Bash(curl *)"
)

MCP_CONFIG="$(dirname "$0")/../mcp-configs/my-config.json"
SYSTEM_PROMPT_FILE="$(dirname "$0")/../prompts/my-prompt.md"

run_agent \
  --allowed-tools "${ALLOWED_TOOLS[@]}" \
  --mcp-config "$MCP_CONFIG" \
  --system-prompt-file "$SYSTEM_PROMPT_FILE" \
  --max-turns 10 \
  --prompt "Do the thing"
```
