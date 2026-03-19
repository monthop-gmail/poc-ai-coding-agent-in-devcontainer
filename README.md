# POC: AI Coding Agent in DevContainer

AI Coding Agent ([OpenCode](https://opencode.ai/)) running in a DevContainer with **Global Team Memory** backed by Redis.

```
┌─────────────────────────────────────────────────┐
│              Docker Compose                      │
│                                                  │
│  ┌──────────────┐  ┌────────────┐  ┌───────────┐│
│  │  workspace   │  │  memory    │  │   redis   ││
│  │  (OpenCode)  │→ │  (MCP)     │→ │   (data)  ││
│  │  DevContainer│  │  :3100     │  │   :6379   ││
│  └──────────────┘  └────────────┘  └───────────┘│
│                                       ▲          │
│                          volume: redis-data      │
│                          (persistent!)           │
└─────────────────────────────────────────────────┘
```

## Features

- **OpenCode** - Open-source AI coding agent with TUI, supports 75+ models
- **Global Memory** - Team-shared memory via custom MCP server + Redis
- **Multi-Provider** - Pre-configured for Qwen (DashScope) and Groq
- **Persistent** - Memory survives container rebuilds via Redis volume
- **DevContainer** - One-click setup in VS Code / GitHub Codespaces

## Quick Start

### 1. Clone & Configure

```bash
git clone https://github.com/monthop-gmail/poc-ai-coding-agent-in-devcontainer.git
cd poc-ai-coding-agent-in-devcontainer
cp .env.example .env
```

Edit `.env` with your API keys:

```env
QWEN_API_KEY=sk-xxxxx
GROQ_API_KEY=gsk_xxxxx
TEAM_NAMESPACE=my-team
```

### 2a. VS Code DevContainer (Recommended)

1. Open folder in VS Code
2. Install **Dev Containers** extension
3. `Ctrl+Shift+P` → "Reopen in Container"
4. Run `opencode` in terminal

### 2b. GitHub Codespaces

Works in both **web browser** and **VS Code Desktop** — no local Docker needed.

1. Click **Code** → **Codespaces** → **Create codespace on main**
2. Wait for container to build (~2-3 min first time)
3. Run `opencode` in terminal

**Setup API keys** (one-time): Go to [GitHub Settings → Codespaces → Secrets](https://github.com/settings/codespaces) and add:
- `QWEN_API_KEY`
- `GROQ_API_KEY`

> **Note:** Redis volume persists as long as the Codespace exists. If you need memory to survive across different Codespaces, consider using a managed Redis service (e.g., [Upstash](https://upstash.com/)) and update `REDIS_URL` in `docker-compose.yml`.

**VS Code Desktop**: Open a running Codespace locally via `Ctrl+Shift+P` → "Codespaces: Connect to Codespace", or click "Open in VS Code Desktop" from the browser.

### 2c. Docker Compose (Manual)

```bash
docker compose up -d
docker compose exec workspace bash
opencode
```

## Available Models

| Provider | Model | Use Case |
|----------|-------|----------|
| **Qwen** | `qwen-coder-plus-latest` | Coding |
| **Qwen** | `qwen3.5-plus` | General |
| **Qwen** | `qwen3.5-397b-a17b` | Large MoE |
| **Qwen** | `qwen-plus-latest` | General |
| **Qwen** | `qwen-turbo-latest` | Fast |
| **Groq** | `llama-3.3-70b-versatile` | Fast inference |
| **Groq** | `qwen-qwq-32b` | Reasoning |
| **Groq** | `meta-llama/llama-4-scout-17b-16e-instruct` | Llama 4 |
| **Groq** | `moonshotai/kimi-k2-instruct-0905` | Kimi K2 |

## Global Memory System

Memory is shared across all team members and persists across container restarts.

### Memory Types

| Type | Purpose | Example |
|------|---------|---------|
| `fact` | Decisions, conventions | "We use TypeScript strict mode" |
| `feedback` | User preferences, corrections | "Don't mock DB in integration tests" |
| `context` | Current work, goals, blockers | "Working on auth refactor" |
| `snippet` | Reusable code patterns | Error handler middleware |

### Memory API (HTTP)

```bash
# Health check
curl http://localhost:3100/health

# Browse all memories
curl http://localhost:3100/memories

# Save a memory
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -d '{"params":{"name":"memory_save","arguments":{
    "type":"fact",
    "id":"deploy-target",
    "content":"We deploy to AWS ECS",
    "metadata":{"author":"devops","tags":["infra"]}
  }}}'

# Search memories
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -d '{"params":{"name":"memory_search","arguments":{"query":"deploy"}}}'
```

### In OpenCode

The agent automatically has access to memory tools via MCP:

```
> search memory for our coding conventions
> save a fact: we use pnpm as package manager
> list all feedback memories
```

## Custom Agents

Pre-configured agents in `.opencode/agents/`:

| Agent | Description |
|-------|-------------|
| `@coder` | Full-stack coding agent with memory awareness |
| `@reviewer` | Code review against team conventions from memory |

## Project Structure

```
.
├── .devcontainer/
│   ├── devcontainer.json    # DevContainer config
│   └── Dockerfile           # Ubuntu + OpenCode
├── .opencode/
│   └── agents/
│       ├── coder.md         # Coding agent definition
│       └── reviewer.md      # Review agent definition
├── memory-server/
│   ├── Dockerfile           # Memory MCP server container
│   ├── package.json
│   └── server.mjs           # MCP server (Redis-backed)
├── scripts/
│   └── setup.sh             # Post-create setup
├── docker-compose.yml       # 3 services: workspace, memory, redis
├── opencode.json            # OpenCode config (providers + MCP)
├── .env.example             # API keys template
└── .gitignore
```

## Adding More Providers

Edit `opencode.json` to add any OpenAI-compatible provider:

```json
{
  "provider": {
    "my-provider": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "My Provider",
      "options": {
        "baseURL": "https://api.example.com/v1",
        "apiKey": "{env:MY_API_KEY}"
      },
      "models": {
        "model-id": {
          "name": "Model Name",
          "limit": { "context": 128000, "output": 16384 }
        }
      }
    }
  }
}
```

## License

MIT
