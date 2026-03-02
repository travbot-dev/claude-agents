# Agents

## Overview

This project runs personal AI agents via `claude -p` on a home server. Each agent is a bash script that wires up permissions, MCP servers, and a prompt, then hands off to Claude. Agents run on cron and deliver results via email through AgentMail.

All agents use the Sonnet model and follow a least-privilege permission model — each agent only gets access to the tools it needs.

## Running Agents

```bash
./run-agent.sh <agent-name>              # Run an agent
./run-agent.sh <agent-name> --dry-run    # Preview the command
./run-agent.sh <agent-name> --verbose    # Show full output
./run-agent.sh                           # List available agents
```

## Agents

### daily-planner

Reviews todo activity from the past week, gives honest productivity feedback, plans the day, and emails a styled HTML summary.

- **Schedule:** Daily at 4:30 AM
- **Data sources:** Today REST API (via curl), week review files from `data/week-reviews/`
- **Output:** HTML email with sections for Week in Review, Feedback, Today's Focus, and Heads Up
- **Permissions:** WebSearch, curl to Today API, AgentMail
- **Week reviews:** The shell script reads the last 4 markdown files (sorted by filename) from `data/week-reviews/` and injects them into the prompt as context. Files are named with a leading number for ordering (e.g., `(273) Week Review.md`). SCP new reviews into that directory as needed.

### weekly-review

Weekly productivity review with metrics and trends.

- **Schedule:** Fridays at 5 PM
- **Data sources:** Today API (via MCP, not curl)
- **Output:** HTML email report
- **Permissions:** Today API MCP (read-only), AgentMail

### social-tracker

Tracks social media engagement across Bluesky and X for both personal and conference accounts.

- **Schedule:** Saturdays at 2 PM
- **Data sources:** Bluesky public API, X API (OAuth 1.0a), historical metrics file
- **Output:** HTML email report, updated `data/social-metrics.json`
- **Permissions:** Read, Write (for metrics persistence), AgentMail
- **Pattern:** The shell script pre-fetches all social data and transforms it with Python before handing off to Claude. This keeps API auth complexity out of the agent and reduces the data Claude needs to process.

### code-digest

Summarizes recent git activity and creates follow-up tasks for loose ends.

- **Schedule:** Daily at 6 PM
- **Data sources:** Local git repo (log, diff, show), source files
- **Output:** Todo items created via Today API MCP
- **Permissions:** Read-only git commands, Read, Grep, Glob, Today API MCP

### custom-task

General-purpose agent for one-off tasks. Permissions are composed via flags.

```bash
./agents/custom-task.sh --web --todo "Research GTD practices and create tasks"
./agents/custom-task.sh --files --git "Review code for security issues"
./agents/custom-task.sh --all "Do everything"
```

Flags: `--web`, `--todo`, `--email`, `--files`, `--git`, `--edit`, `--all`

## Project Structure

```
agents/           Shell scripts, one per agent
prompts/          System prompt markdown files
mcp-configs/      MCP server configurations (email-only, readonly, todo-and-email)
lib/              Shared helpers (agent-helpers.sh, x-oauth.sh)
data/             Runtime data (social metrics, week reviews)
run-agent.sh      Entry point that dispatches to agent scripts
crontab.example   Example cron schedule
```

## Repository Setup

This is a fork (`travbot-dev/claude-agents`) of the original repo (`travisdock/claude-agents`).

- **`origin`** — upstream original repo (`travisdock/claude-agents`)
- **`fork`** — this fork (`travbot-dev/claude-agents`)

**Workflow:**
- Keep `main` in sync with upstream: `git fetch origin main && git merge origin/main --ff-only && git push fork main`
- Feature branches should be based off `main`
- PRs go against the original repo: `gh pr create --repo travisdock/claude-agents --head travbot-dev:<branch>`
- After a PR is merged upstream, update local and fork main, then delete the feature branch locally and on the fork

## Key Patterns

**Data access approaches used across agents:**
- **Curl in prompt** (daily-planner): Claude makes API calls directly via restricted bash permission
- **Pre-fetch in shell** (social-tracker): Shell script fetches and transforms data, writes to a file, Claude reads the file
- **MCP servers** (weekly-review): Claude uses native MCP tool calls for structured API access
- **File injection** (daily-planner week reviews): Shell script reads local files and injects content directly into the prompt text — no Read permission needed

**Permission model:** Every agent runs with `--permission-mode dontAsk`. Tools are explicitly allowed or denied. The default is deny-all.

**Configuration:** API keys and URLs live in `.env`. MCP server configs are JSON files in `mcp-configs/`.
