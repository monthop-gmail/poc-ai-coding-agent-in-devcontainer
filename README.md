# POC: AI Coding Agent in DevContainer

AI Coding Agent ([OpenCode](https://opencode.ai/)) ทำงานใน DevContainer พร้อม **Global Team Memory** เก็บข้อมูลถาวรด้วย Redis

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

## คุณสมบัติ

- **OpenCode** - AI coding agent แบบ open-source รองรับ 75+ models
- **Global Memory** - หน่วยความจำกลางของทีม ผ่าน MCP server + Redis
- **Multi-Provider** - ตั้งค่า Qwen (DashScope) และ Groq มาให้พร้อมใช้
- **Persistent** - Memory ไม่หายแม้ rebuild container (เก็บใน Redis volume)
- **DevContainer** - ตั้งค่าครั้งเดียว ใช้ได้ทั้ง VS Code และ GitHub Codespaces

## เริ่มต้นใช้งาน

### 1. Clone และตั้งค่า

```bash
git clone https://github.com/monthop-gmail/poc-ai-coding-agent-in-devcontainer.git
cd poc-ai-coding-agent-in-devcontainer
cp .env.example .env
```

แก้ไข `.env` ใส่ API keys:

```env
QWEN_API_KEY=sk-xxxxx
GROQ_API_KEY=gsk_xxxxx
TEAM_NAMESPACE=my-team
```

### 2a. VS Code DevContainer (แนะนำ)

1. เปิดโฟลเดอร์ใน VS Code
2. ติดตั้ง extension **Dev Containers**
3. `Ctrl+Shift+P` → "Reopen in Container"
4. รัน `opencode` ใน terminal

### 2b. GitHub Codespaces

ใช้ได้ทั้ง **web browser** และ **VS Code Desktop** โดยไม่ต้องติดตั้ง Docker ในเครื่อง

1. กด **Code** → **Codespaces** → **Create codespace on main**
2. รอ container build (~2-3 นาทีครั้งแรก)
3. รัน `opencode` ใน terminal

**ตั้งค่า API keys** (ครั้งเดียว): ไปที่ [GitHub Settings → Codespaces → Secrets](https://github.com/settings/codespaces) แล้วเพิ่ม:
- `QWEN_API_KEY`
- `GROQ_API_KEY`

> **หมายเหตุ:** Redis volume จะคงอยู่ตราบใดที่ Codespace ยังไม่ถูกลบ หากต้องการ memory ที่ใช้ร่วมกันข้าม Codespace ควรใช้ managed Redis (เช่น [Upstash](https://upstash.com/)) แล้วอัปเดต `REDIS_URL` ใน `docker-compose.yml`

**ใช้ผ่าน VS Code Desktop**: กด `Ctrl+Shift+P` → "Codespaces: Connect to Codespace" หรือกด "Open in VS Code Desktop" จาก browser

### 2c. Docker Compose (Manual)

```bash
docker compose up -d
docker compose exec workspace bash
opencode
```

## โหมดการใช้งาน OpenCode

| โหมด | คำสั่ง | รายละเอียด |
|------|--------|-----------|
| **TUI** (Terminal) | `opencode` | ใช้ในเทอร์มินัลโดยตรง |
| **Web UI** | `opencode web` | เปิดผ่าน browser ที่ port 4096 |
| **TUI + Web พร้อมกัน** | เปิดทั้ง 2 | แชร์ session เดียวกัน |

> **Web UI ใน DevContainer/Codespaces:** Port 4096 ถูกตั้งค่า forward ไว้แล้ว เปิด `opencode web` แล้ว VS Code จะแจ้งให้กด "Open in Browser" อัตโนมัติ

## Models ที่พร้อมใช้

| Provider | Model | ใช้ทำอะไร |
|----------|-------|----------|
| **Qwen** | `qwen-coder-plus-latest` | เขียนโค้ด |
| **Qwen** | `qwen3.5-plus` | งานทั่วไป |
| **Qwen** | `qwen3.5-397b-a17b` | Large MoE |
| **Qwen** | `qwen-plus-latest` | งานทั่วไป |
| **Qwen** | `qwen-turbo-latest` | เร็ว ประหยัด |
| **Groq** | `llama-3.3-70b-versatile` | Inference เร็ว |
| **Groq** | `qwen-qwq-32b` | วิเคราะห์/ให้เหตุผล |
| **Groq** | `meta-llama/llama-4-scout-17b-16e-instruct` | Llama 4 |
| **Groq** | `moonshotai/kimi-k2-instruct-0905` | Kimi K2 |

## ระบบ Global Memory

Memory ถูกแชร์ข้ามทุกคนในทีม และคงอยู่แม้ restart container

### ประเภท Memory

| ประเภท | วัตถุประสงค์ | ตัวอย่าง |
|--------|-------------|---------|
| `fact` | ข้อตกลง, แนวปฏิบัติ | "ทีมใช้ TypeScript strict mode" |
| `feedback` | ความชอบ, สิ่งที่ต้องแก้ไข | "ห้าม mock DB ใน integration tests" |
| `context` | งานที่ทำอยู่, เป้าหมาย, ปัญหา | "กำลัง refactor ระบบ auth" |
| `snippet` | โค้ดที่ใช้ซ้ำได้ | Error handler middleware |

### Memory API (HTTP)

```bash
# ตรวจสอบสถานะ
curl http://localhost:3100/health

# ดู memory ทั้งหมด
curl http://localhost:3100/memories

# บันทึก memory
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -d '{"params":{"name":"memory_save","arguments":{
    "type":"fact",
    "id":"deploy-target",
    "content":"ทีม deploy ขึ้น AWS ECS",
    "metadata":{"author":"devops","tags":["infra"]}
  }}}'

# ค้นหา memory
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -d '{"params":{"name":"memory_search","arguments":{"query":"deploy"}}}'
```

### ใช้ใน OpenCode

Agent เข้าถึง memory tools ผ่าน MCP โดยอัตโนมัติ:

```
> ค้นหา memory เกี่ยวกับ coding conventions ของทีม
> บันทึก fact: ทีมใช้ pnpm เป็น package manager
> แสดง feedback memories ทั้งหมด
```

## Custom Agents

Agent ที่ตั้งค่าไว้ใน `.opencode/agents/`:

| Agent | รายละเอียด |
|-------|-----------|
| `@coder` | เขียนโค้ด full-stack พร้อมใช้ memory ของทีม |
| `@reviewer` | รีวิวโค้ดตาม conventions ที่เก็บใน memory |

## นำไปใช้กับ Project ที่มีอยู่แล้ว

รันคำสั่งเดียวใน project ที่ต้องการ:

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/monthop-gmail/poc-ai-coding-agent-in-devcontainer/main/setup.sh | bash
```

Script จะเพิ่ม `.ai-agent/` เป็น git submodule โค้ดเดิมไม่ถูกแก้ไข อัปเดตง่าย ลบออกก็ง่าย

ดูคู่มือฉบับเต็ม: **[docs/integrate-existing-project.md](docs/integrate-existing-project.md)**

## ตัวอย่างการใช้งาน

| ตัวอย่าง | รายละเอียด | วิธีใช้ |
|---------|-----------|--------|
| [Odoo Module Dev](examples/odoo-module-dev/) | พัฒนา Odoo module พร้อม seed ความรู้ ORM, views, security | `bash examples/odoo-module-dev/seed-memory.sh` |
| [PWA Dev](examples/pwa-dev/) | พัฒนา Progressive Web App: offline-first, service worker, push notification | `bash examples/pwa-dev/seed-memory.sh` |

## โครงสร้างโปรเจกต์

```
.
├── .devcontainer/
│   ├── devcontainer.json    # ตั้งค่า DevContainer
│   └── Dockerfile           # Ubuntu + OpenCode
├── .opencode/
│   └── agents/
│       ├── coder.md         # Agent สำหรับเขียนโค้ด
│       └── reviewer.md      # Agent สำหรับรีวิวโค้ด
├── memory-server/
│   ├── Dockerfile           # Container ของ Memory MCP server
│   ├── package.json
│   └── server.mjs           # MCP server (ใช้ Redis เก็บข้อมูล)
├── examples/
│   └── odoo-module-dev/     # ตัวอย่าง: พัฒนา Odoo module
├── scripts/
│   └── setup.sh             # Script ตั้งค่าหลังสร้าง container
├── docker-compose.yml       # 3 services: workspace, memory, redis
├── opencode.json            # ตั้งค่า OpenCode (providers + MCP)
├── .env.example             # ตัวอย่าง API keys
└── .gitignore
```

## เพิ่ม Provider อื่น

แก้ไข `opencode.json` เพื่อเพิ่ม provider ที่รองรับ OpenAI-compatible API:

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
