# ตัวอย่าง: ใช้ AI Coding Agent พัฒนา PWA (Progressive Web App)

ตัวอย่างการใช้ OpenCode + Global Memory พัฒนา PWA อย่างมีประสิทธิภาพ

## ตั้งค่า

### 1. Seed ความรู้ PWA ลง memory

```bash
bash examples/pwa-dev/seed-memory.sh
```

### 2. Copy agent ไปใช้

```bash
cp examples/pwa-dev/pwa-agent.md .opencode/agents/
```

### 3. ใช้ PWA agent

```
@pwa สร้าง PWA ด้วย Vite + React สำหรับ task management app
```

## ตัวอย่าง Prompts

```
# Scaffold โปรเจกต์
@pwa scaffold PWA ด้วย Vite + React + TypeScript พร้อม offline support

# Manifest
@pwa สร้าง manifest.json สำหรับ app ชื่อ "TaskFlow" รองรับ standalone mode

# Service Worker
@pwa สร้าง service worker ด้วย Workbox สำหรับ cache-first strategy กับ static assets
  และ network-first สำหรับ API calls

# Offline
@pwa เพิ่ม offline page แสดงเมื่อไม่มี internet พร้อม cached data จาก IndexedDB

# Push Notification
@pwa เพิ่ม push notification ด้วย Web Push API พร้อม permission request UX

# Install Prompt
@pwa สร้าง custom install prompt (beforeinstallprompt) แบบ bottom banner

# App Shell
@pwa สร้าง App Shell architecture แยก shell กับ content ให้โหลดเร็ว

# Icons
@pwa สร้าง icon set สำหรับ PWA ทุกขนาดที่ต้องการ (192, 512, maskable)

# Performance
@pwa optimize Lighthouse score ให้ได้ 90+ ทุกหมวด

# Background Sync
@pwa เพิ่ม background sync สำหรับ form submission ที่ทำขณะ offline
```

## สิ่งที่ Agent จำได้หลัง Seed

- โครงสร้าง PWA มาตรฐาน (manifest, service worker, app shell)
- Workbox patterns (caching strategies)
- Offline-first architecture
- Web APIs: Push, Background Sync, IndexedDB
- Install prompt UX patterns
- Lighthouse checklist
- ข้อตกลงของทีม (testing, performance budgets)

## ไฟล์

| ไฟล์ | รายละเอียด |
|------|-----------|
| `seed-memory.sh` | Seed ความรู้ PWA ลง global memory |
| `pwa-agent.md` | Agent เฉพาะทางสำหรับพัฒนา PWA |
