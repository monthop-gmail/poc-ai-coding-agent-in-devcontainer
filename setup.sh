#!/bin/bash
# ===========================================
# AI Coding Agent - Setup Script
# ===========================================
# วิธีใช้: รันในโฟลเดอร์ project ที่ต้องการเพิ่ม AI agent
#
#   curl -fsSL https://raw.githubusercontent.com/monthop-gmail/poc-ai-coding-agent-in-devcontainer/main/setup.sh | bash
#
# หรือ clone มาแล้วรัน:
#   bash .ai-agent/setup.sh
#

set -e

# สี
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}[info]${NC} $1"; }
ok()    { echo -e "${GREEN}[ok]${NC} $1"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $1"; }
err()   { echo -e "${RED}[error]${NC} $1"; }

REPO_URL="https://github.com/monthop-gmail/poc-ai-coding-agent-in-devcontainer.git"
SUBMODULE_DIR=".ai-agent"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  AI Coding Agent - Setup${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# ===========================================
# ตรวจสอบ
# ===========================================
if [ ! -d ".git" ]; then
  err "ไม่พบ .git ในโฟลเดอร์นี้ กรุณารันใน root ของ git project"
  exit 1
fi

if [ -d "$SUBMODULE_DIR" ]; then
  warn ".ai-agent/ มีอยู่แล้ว จะ update แทน"
  git submodule update --remote "$SUBMODULE_DIR"
  ok "อัปเดต submodule สำเร็จ"
else
  # ===========================================
  # 1. เพิ่ม submodule
  # ===========================================
  info "เพิ่ม git submodule..."
  git submodule add "$REPO_URL" "$SUBMODULE_DIR"
  ok "เพิ่ม submodule .ai-agent/"
fi

# ===========================================
# 2. สร้าง .devcontainer (ชี้ไป submodule)
# ===========================================
if [ -d ".devcontainer" ]; then
  warn ".devcontainer/ มีอยู่แล้ว ข้าม (ตรวจสอบด้วยตนเอง)"
else
  info "สร้าง .devcontainer/..."
  mkdir -p .devcontainer

  cat > .devcontainer/devcontainer.json << 'DEVCONTAINER'
{
  "name": "AI Coding Agent",
  "dockerComposeFile": ["../.ai-agent/docker-compose.yml", "../docker-compose.override.yml"],
  "service": "workspace",
  "workspaceFolder": "/workspace",

  "features": {
    "ghcr.io/devcontainers/features/git:1": {}
  },

  "forwardPorts": [4096, 3100],
  "portsAttributes": {
    "4096": { "label": "OpenCode Web UI", "onAutoForward": "notify" },
    "3100": { "label": "Memory MCP Server", "onAutoForward": "silent" }
  },

  "postCreateCommand": "bash /workspace/.ai-agent/scripts/setup.sh",
  "postStartCommand": "echo '🤖 OpenCode Agent ready! Run: opencode  |  Web UI: opencode web'",

  "remoteEnv": {
    "QWEN_API_KEY": "${localEnv:QWEN_API_KEY}",
    "GROQ_API_KEY": "${localEnv:GROQ_API_KEY}"
  },

  "remoteUser": "dev"
}
DEVCONTAINER

  ok "สร้าง .devcontainer/devcontainer.json"
fi

# ===========================================
# 3. สร้าง docker-compose.override.yml
# ===========================================
if [ -f "docker-compose.override.yml" ]; then
  warn "docker-compose.override.yml มีอยู่แล้ว ข้าม"
else
  info "สร้าง docker-compose.override.yml..."

  cat > docker-compose.override.yml << 'OVERRIDE'
# Override: mount project ของคุณเข้า workspace
# แก้ไขไฟล์นี้ได้ตามต้องการ โดยไม่กระทบ .ai-agent/
services:
  workspace:
    volumes:
      - .:/workspace:cached
    environment:
      - QWEN_API_KEY=${QWEN_API_KEY:-}
      - GROQ_API_KEY=${GROQ_API_KEY:-}
OVERRIDE

  ok "สร้าง docker-compose.override.yml"
fi

# ===========================================
# 4. สร้าง opencode.json (ถ้ายังไม่มี)
# ===========================================
if [ -f "opencode.json" ]; then
  warn "opencode.json มีอยู่แล้ว ข้าม"
else
  info "สร้าง opencode.json..."

  cat > opencode.json << 'OPENCODE'
{
  "$schema": "https://opencode.ai/config.json",

  "provider": {
    "qwen": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Qwen (DashScope)",
      "options": {
        "baseURL": "https://dashscope.aliyuncs.com/compatible-mode/v1",
        "apiKey": "{env:QWEN_API_KEY}"
      },
      "models": {
        "qwen3.5-plus": {
          "name": "Qwen 3.5 Plus",
          "limit": { "context": 131072, "output": 16384 }
        },
        "qwen-coder-plus-latest": {
          "name": "Qwen Coder Plus",
          "limit": { "context": 131072, "output": 16384 }
        }
      }
    },
    "groq": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Groq",
      "options": {
        "baseURL": "https://api.groq.com/openai/v1",
        "apiKey": "{env:GROQ_API_KEY}"
      },
      "models": {
        "llama-3.3-70b-versatile": {
          "name": "Llama 3.3 70B",
          "limit": { "context": 128000, "output": 32768 }
        },
        "moonshotai/kimi-k2-instruct-0905": {
          "name": "Kimi K2 Instruct",
          "limit": { "context": 131072, "output": 16384 }
        }
      }
    }
  },

  "mcp": {
    "global-memory": {
      "type": "local",
      "command": ["node", "/workspace/.ai-agent/memory-server/server.mjs"],
      "environment": {
        "REDIS_URL": "redis://redis:6379",
        "MEMORY_NAMESPACE": "default-team",
        "MCP_MODE": "stdio"
      },
      "enabled": true
    }
  },

  "instructions": [
    "You have access to a global team memory system via the global-memory MCP server.",
    "Use memory_search before starting work to check if there are relevant memories.",
    "Always save user feedback and corrections to memory for the team."
  ]
}
OPENCODE

  ok "สร้าง opencode.json"
fi

# ===========================================
# 5. สร้าง .env (ถ้ายังไม่มี)
# ===========================================
if [ -f ".env" ]; then
  warn ".env มีอยู่แล้ว ข้าม"
else
  info "สร้าง .env..."

  cat > .env << 'ENVFILE'
# AI Provider API Keys
QWEN_API_KEY=sk-xxxxx
GROQ_API_KEY=gsk_xxxxx

# Team namespace (แยก memory ต่างทีม/project)
TEAM_NAMESPACE=my-team
ENVFILE

  ok "สร้าง .env (อย่าลืมแก้ใส่ API keys!)"
fi

# ===========================================
# 6. อัปเดต .gitignore
# ===========================================
IGNORE_ENTRIES=(".env" ".opencode/sessions/" ".opencode/cache/")

for entry in "${IGNORE_ENTRIES[@]}"; do
  if ! grep -qF "$entry" .gitignore 2>/dev/null; then
    echo "$entry" >> .gitignore
    info "เพิ่ม $entry ใน .gitignore"
  fi
done
ok "อัปเดต .gitignore"

# ===========================================
# สรุป
# ===========================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Setup เสร็จเรียบร้อย!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  โครงสร้างที่สร้างให้:"
echo ""
echo "  your-project/"
echo "  ├── .ai-agent/               ← submodule (infra ทั้งหมด)"
echo "  ├── .devcontainer/"
echo "  │   └── devcontainer.json    ← ชี้ไป .ai-agent/"
echo "  ├── docker-compose.override.yml  ← config เฉพาะ project"
echo "  ├── opencode.json            ← ตั้งค่า AI providers"
echo "  └── .env                     ← API keys (ไม่เข้า git)"
echo ""
echo "  ขั้นตอนถัดไป:"
echo ""
echo -e "  ${YELLOW}1.${NC} แก้ไข .env ใส่ API keys"
echo -e "  ${YELLOW}2.${NC} เปิด VS Code → Ctrl+Shift+P → 'Reopen in Container'"
echo -e "  ${YELLOW}3.${NC} รัน ${GREEN}opencode${NC} ใน terminal"
echo ""
echo "  อัปเดต agent ภายหลัง:"
echo -e "  ${BLUE}git submodule update --remote .ai-agent${NC}"
echo ""
