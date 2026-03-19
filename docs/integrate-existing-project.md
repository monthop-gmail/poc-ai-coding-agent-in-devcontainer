# วิธีเพิ่ม AI Coding Agent เข้า Project ที่มีอยู่แล้ว

คู่มือนี้สำหรับน้องๆ ที่มี project อยู่แล้ว และต้องการเพิ่ม OpenCode + Global Memory เข้าไปใช้

## สิ่งที่จะได้

- **OpenCode** AI coding agent ใช้ได้ทั้ง TUI และ Web UI
- **Global Memory** หน่วยความจำกลางของทีม ไม่หายแม้ rebuild container
- **Custom Agents** ตั้งค่า agent เฉพาะทางสำหรับ project
- **Multi-Provider** ใช้ได้หลาย AI providers (Qwen, Groq, ฯลฯ)

## ขั้นตอน

### 1. Clone template

```bash
git clone https://github.com/monthop-gmail/poc-ai-coding-agent-in-devcontainer.git /tmp/ai-agent
```

### 2. Copy ไฟล์เข้า project

```bash
cd your-project

# ไฟล์หลัก (จำเป็นทั้งหมด)
cp -r /tmp/ai-agent/.devcontainer  .
cp -r /tmp/ai-agent/memory-server  .
cp -r /tmp/ai-agent/scripts        .
cp    /tmp/ai-agent/docker-compose.yml  .
cp    /tmp/ai-agent/opencode.json       .
cp    /tmp/ai-agent/.env.example        .

# Agent definitions
cp -r /tmp/ai-agent/.opencode  .
```

### 3. ปรับ docker-compose.yml ให้เข้ากับ project

ถ้า project มี `docker-compose.yml` อยู่แล้ว ให้ **merge** services เข้าไป ไม่ใช่ overwrite

#### กรณี A: Project ยังไม่มี docker-compose.yml

ใช้ไฟล์ที่ copy มาได้เลย ไม่ต้องแก้อะไร

#### กรณี B: Project มี docker-compose.yml อยู่แล้ว

เพิ่ม 2 services (`redis` + `memory`) และ volumes เข้าไปในไฟล์เดิม:

```yaml
services:
  # ... services เดิมของ project ...

  # === เพิ่มส่วนนี้ ===
  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes --save 60 1
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
    restart: unless-stopped

  memory:
    build:
      context: ./memory-server
      dockerfile: Dockerfile
    environment:
      - REDIS_URL=redis://redis:6379
      - MCP_PORT=3100
      - MEMORY_NAMESPACE=${TEAM_NAMESPACE:-default-team}
    ports:
      - "3100:3100"
    depends_on:
      redis:
        condition: service_healthy
    restart: unless-stopped

volumes:
  # ... volumes เดิม ...
  redis-data:
    name: opencode-global-memory
```

#### กรณี C: Project ใช้ devcontainer อยู่แล้ว

เพิ่มส่วนเหล่านี้ใน `devcontainer.json` ที่มีอยู่:

```jsonc
{
  // ... config เดิม ...

  // เพิ่ม port forwarding
  "forwardPorts": [4096, 3100],
  "portsAttributes": {
    "4096": { "label": "OpenCode Web UI", "onAutoForward": "notify" },
    "3100": { "label": "Memory MCP Server", "onAutoForward": "silent" }
  },

  // เพิ่ม environment
  "remoteEnv": {
    "QWEN_API_KEY": "${localEnv:QWEN_API_KEY}",
    "GROQ_API_KEY": "${localEnv:GROQ_API_KEY}"
  },

  // เพิ่ม postCreateCommand (หรือ merge กับที่มีอยู่)
  "postCreateCommand": "bash scripts/setup.sh"
}
```

### 4. ตั้งค่า API Keys

```bash
cp .env.example .env
```

แก้ไข `.env`:

```env
QWEN_API_KEY=sk-xxxxx
GROQ_API_KEY=gsk_xxxxx
TEAM_NAMESPACE=my-team    # ตั้งชื่อทีมเพื่อแยก memory
```

หรือถ้าใช้ **GitHub Codespaces** ตั้งค่าที่:
[GitHub Settings → Codespaces → Secrets](https://github.com/settings/codespaces)

### 5. อัปเดต .gitignore

เพิ่มใน `.gitignore`:

```
# AI Agent
.env
memory-server/node_modules/
.opencode/sessions/
.opencode/cache/
```

### 6. (ทางเลือก) Seed Memory สำหรับ project

เลือก seed ตามประเภท project:

```bash
# สำหรับ Odoo module development
cp -r /tmp/ai-agent/examples/odoo-module-dev examples/
bash examples/odoo-module-dev/seed-memory.sh

# สำหรับ PWA development
cp -r /tmp/ai-agent/examples/pwa-dev examples/
bash examples/pwa-dev/seed-memory.sh
```

หรือสร้าง seed เองสำหรับ project:

```bash
# บันทึก convention ของ project
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -d '{"params":{"name":"memory_save","arguments":{
    "type":"fact",
    "id":"project-stack",
    "content":"Project ใช้ Next.js 15 + Prisma + PostgreSQL, deploy บน Vercel",
    "metadata":{"author":"lead","tags":["stack"]}
  }}}'
```

### 7. เริ่มใช้งาน

```bash
# VS Code DevContainer
# Ctrl+Shift+P → "Reopen in Container"

# หรือ Docker Compose
docker compose up -d
docker compose exec workspace bash

# เปิด OpenCode
opencode              # TUI mode
opencode web          # Web UI (port 4096)
```

## สร้าง Agent เฉพาะ Project

สร้างไฟล์ `.opencode/agents/my-agent.md`:

```markdown
---
name: my-agent
description: Agent สำหรับ project นี้โดยเฉพาะ
model: anthropic/claude-sonnet-4-20250514
---

คุณเป็น developer ของ project [ชื่อ project]

## ก่อนเริ่มงาน
1. รัน memory_search หา context ที่เกี่ยวข้อง
2. รัน memory_list type feedback ดูข้อตกลงของทีม

## Tech Stack
- [ระบุ tech stack ของ project]

## Conventions
- [ระบุแนวปฏิบัติของทีม]

## หลังทำงานเสร็จ
1. บันทึก decisions/patterns ใหม่เป็น fact memories
2. บันทึก feedback จาก user เป็น feedback memories
```

## Checklist

- [ ] Copy ไฟล์ `.devcontainer/`, `memory-server/`, `scripts/`, `opencode.json`
- [ ] ปรับ `docker-compose.yml` (merge หรือใช้ไฟล์ใหม่)
- [ ] ตั้งค่า `.env` ใส่ API keys
- [ ] อัปเดต `.gitignore`
- [ ] ทดสอบ `docker compose up -d`
- [ ] ตรวจสอบ memory server: `curl http://localhost:3100/health`
- [ ] Seed memory สำหรับ project (ถ้าต้องการ)
- [ ] สร้าง agent เฉพาะ project (ถ้าต้องการ)
- [ ] ทดสอบ `opencode` ใน container

## FAQ

### Q: ใช้กับ Codespaces ได้ไหม?
ได้ครับ กด "Create codespace" บน GitHub ได้เลย ตั้ง API keys ผ่าน Codespaces Secrets

### Q: Memory จะหายไหมถ้า rebuild container?
ไม่หาย Redis เก็บใน Docker volume ที่แยกจาก container

### Q: ใช้ AI provider อื่นได้ไหม?
ได้ แก้ `opencode.json` เพิ่ม provider ที่รองรับ OpenAI-compatible API ดูตัวอย่างใน [README](../README.md#เพิ่ม-provider-อื่น)

### Q: ทีมหลายคนใช้ memory ร่วมกันยังไง?
ใช้ `TEAM_NAMESPACE` เดียวกันใน `.env` และชี้ Redis ไปที่เดียวกัน (เช่น Redis cloud) ถ้าอยู่คนละเครื่อง

### Q: มี project หลายตัว memory จะปนกันไหม?
ไม่ปน ตั้ง `TEAM_NAMESPACE` ต่างกันในแต่ละ project เช่น `project-a`, `project-b`
