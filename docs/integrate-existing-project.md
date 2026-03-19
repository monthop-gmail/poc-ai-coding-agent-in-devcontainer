# วิธีเพิ่ม AI Coding Agent เข้า Project ที่มีอยู่แล้ว

## วิธีที่ 1: รันคำสั่งเดียว (แนะนำ)

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/monthop-gmail/poc-ai-coding-agent-in-devcontainer/main/setup.sh | bash
```

Script จะทำให้อัตโนมัติ:
- เพิ่ม `.ai-agent/` เป็น git submodule
- สร้าง `.devcontainer/devcontainer.json` ชี้ไป submodule
- สร้าง `docker-compose.override.yml` สำหรับ config เฉพาะ project
- สร้าง `opencode.json` พร้อม providers
- สร้าง `.env` template
- อัปเดต `.gitignore`

**หลังรัน script:**

```bash
# 1. แก้ .env ใส่ API keys
nano .env

# 2. เปิด VS Code → Reopen in Container
# หรือ
docker compose -f .ai-agent/docker-compose.yml -f docker-compose.override.yml up -d
```

## วิธีที่ 2: ทำเอง step-by-step

### 1. เพิ่ม submodule

```bash
cd your-project
git submodule add https://github.com/monthop-gmail/poc-ai-coding-agent-in-devcontainer.git .ai-agent
```

### 2. สร้าง .devcontainer/devcontainer.json

```jsonc
{
  "name": "AI Coding Agent",
  "dockerComposeFile": ["../.ai-agent/docker-compose.yml", "../docker-compose.override.yml"],
  "service": "workspace",
  "workspaceFolder": "/workspace",

  "forwardPorts": [4096, 3100],
  "portsAttributes": {
    "4096": { "label": "OpenCode Web UI", "onAutoForward": "notify" },
    "3100": { "label": "Memory MCP Server", "onAutoForward": "silent" }
  },

  "postCreateCommand": "bash /workspace/.ai-agent/scripts/setup.sh",

  "remoteEnv": {
    "QWEN_API_KEY": "${localEnv:QWEN_API_KEY}",
    "GROQ_API_KEY": "${localEnv:GROQ_API_KEY}"
  },

  "remoteUser": "dev"
}
```

### 3. สร้าง docker-compose.override.yml

```yaml
services:
  workspace:
    volumes:
      - .:/workspace:cached
    environment:
      - QWEN_API_KEY=${QWEN_API_KEY:-}
      - GROQ_API_KEY=${GROQ_API_KEY:-}
```

### 4. สร้าง opencode.json และ .env

ดูตัวอย่างใน `.ai-agent/opencode.json` และ `.ai-agent/.env.example`

## โครงสร้างหลัง setup

```
your-project/
├── src/                           # โค้ดของน้องๆ (ไม่ถูกแก้)
├── package.json                   # ไฟล์เดิมของ project (ไม่ถูกแก้)
├── .ai-agent/                     # ← git submodule (infra ทั้งหมดอยู่ที่นี่)
│   ├── .devcontainer/
│   ├── memory-server/
│   ├── docker-compose.yml
│   ├── scripts/
│   └── examples/
├── .devcontainer/
│   └── devcontainer.json          # ← ชี้ไป .ai-agent/ (ไฟล์เดียว)
├── docker-compose.override.yml    # ← config เฉพาะ project
├── opencode.json                  # ← ตั้งค่า AI providers
├── .env                           # ← API keys (ไม่เข้า git)
└── .gitignore                     # ← เพิ่ม .env
```

**ข้อดี:**
- โค้ดน้องๆ **ไม่ถูกแก้ไข** เลยแม้แต่ไฟล์เดียว
- Agent infra อยู่ใน `.ai-agent/` ทั้งหมด จะลบออกก็ `git rm .ai-agent`
- อัปเดต agent version: `git submodule update --remote .ai-agent`
- Config เฉพาะ project อยู่ใน `docker-compose.override.yml` + `opencode.json`

## อัปเดต Agent เวอร์ชันใหม่

```bash
git submodule update --remote .ai-agent
git add .ai-agent
git commit -m "อัปเดต ai-agent เป็นเวอร์ชันล่าสุด"
```

## ลบ Agent ออกจาก Project

```bash
git submodule deinit .ai-agent
git rm .ai-agent
rm -rf .git/modules/.ai-agent
git commit -m "ลบ ai-agent"
```

## สำหรับคนที่ Clone Project มาใหม่

```bash
git clone --recurse-submodules https://github.com/your-org/your-project.git

# หรือถ้า clone แล้วยังไม่มี submodule
git submodule update --init
```

## Seed Memory สำหรับ Project

```bash
# เข้า container ก่อน
docker compose exec workspace bash

# เลือก seed ตามประเภทงาน
bash .ai-agent/examples/odoo-module-dev/seed-memory.sh    # Odoo
bash .ai-agent/examples/pwa-dev/seed-memory.sh            # PWA

# หรือบันทึก convention ของ project เอง
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -d '{"params":{"name":"memory_save","arguments":{
    "type":"fact",
    "id":"project-stack",
    "content":"ใช้ Next.js 15 + Prisma + PostgreSQL",
    "metadata":{"author":"lead","tags":["stack"]}
  }}}'
```

## FAQ

### Q: Clone มาแล้ว .ai-agent/ ว่างเปล่า?
รัน `git submodule update --init`

### Q: ใช้กับ Codespaces ได้ไหม?
ได้ ตั้ง API keys ผ่าน [Codespaces Secrets](https://github.com/settings/codespaces)

### Q: อยากเพิ่ม services อื่นของ project (เช่น PostgreSQL)?
เพิ่มใน `docker-compose.override.yml` ไม่ต้องแก้ไฟล์ใน `.ai-agent/`

### Q: อยากลบ agent ออกจาก project?
รัน `git submodule deinit .ai-agent && git rm .ai-agent` แค่นั้น โค้ดเดิมไม่หาย

### Q: Memory จะปนข้าม project ไหม?
ไม่ปน ตั้ง `TEAM_NAMESPACE` ต่างกันในแต่ละ project
