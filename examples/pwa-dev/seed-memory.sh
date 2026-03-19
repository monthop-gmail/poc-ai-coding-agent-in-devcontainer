#!/bin/bash
# ===========================================
# Seed Global Memory สำหรับพัฒนา PWA
# ===========================================
# วิธีใช้: bash examples/pwa-dev/seed-memory.sh

MEMORY_URL="${MEMORIX_URL:-http://localhost:3100}"

save_memory() {
  local type=$1
  local id=$2
  local content=$3
  local author=${4:-"seed-script"}
  local tags=$5

  curl -s -X POST "$MEMORY_URL/mcp" \
    -H "Content-Type: application/json" \
    -d "{\"params\":{\"name\":\"memory_save\",\"arguments\":{\"type\":\"$type\",\"id\":\"$id\",\"content\":$(echo "$content" | jq -Rs .),\"metadata\":{\"author\":\"$author\",\"tags\":$tags}}}}" \
    | jq -r '.content[0].text // .error'
}

echo "============================================"
echo "  Seeding PWA Development Knowledge"
echo "============================================"
echo ""

# ===========================================
# Facts - PWA Conventions
# ===========================================
echo "[facts] PWA conventions..."

save_memory "fact" "pwa-manifest-required" \
  "manifest.json ต้องมี: name, short_name, start_url, display (standalone/fullscreen), background_color, theme_color, icons (อย่างน้อย 192x192 และ 512x512 รวม maskable). ใส่ id เพื่อให้ browser ระบุ app identity ได้ถูกต้อง. ตั้ง scope เพื่อจำกัดขอบเขตของ app." \
  "seed" '["pwa","manifest"]'

save_memory "fact" "pwa-service-worker-lifecycle" \
  "Service Worker lifecycle: install → activate → fetch. ใน install event ให้ precache static assets. ใน activate event ให้ลบ cache เก่า. fetch event ใช้ตัดสินใจ caching strategy. ใช้ skipWaiting() และ clients.claim() เพื่อ activate ทันที. อย่าลืม handle update flow แจ้ง user ว่ามีเวอร์ชันใหม่." \
  "seed" '["pwa","service-worker","lifecycle"]'

save_memory "fact" "pwa-caching-strategies" \
  "Caching strategies: (1) Cache First - static assets, fonts, images ที่ไม่เปลี่ยนบ่อย. (2) Network First - API responses, dynamic content ที่ต้องการข้อมูลล่าสุด. (3) Stale While Revalidate - content ที่ยอมรับ stale ได้ชั่วคราว เช่น avatars, non-critical data. (4) Network Only - auth, payment, analytics. (5) Cache Only - precached app shell." \
  "seed" '["pwa","cache","strategy"]'

save_memory "fact" "pwa-offline-patterns" \
  "Offline patterns: (1) App Shell + dynamic content จาก cache/IndexedDB. (2) Offline fallback page สำหรับ navigation requests ที่ไม่มีใน cache. (3) Queue failed requests ด้วย Background Sync API แล้ว retry เมื่อ online. (4) ใช้ IndexedDB (ผ่าน idb หรือ Dexie.js) สำหรับ structured data ไม่ใช่ localStorage. (5) แสดง online/offline indicator ให้ user รู้สถานะ." \
  "seed" '["pwa","offline"]'

save_memory "fact" "pwa-installability" \
  "เงื่อนไข installability: (1) valid manifest.json with required fields. (2) Service worker registered successfully. (3) served over HTTPS (localhost OK for dev). (4) มี fetch event handler ใน service worker. จับ beforeinstallprompt event เพื่อสร้าง custom install UX. อย่าแสดง install prompt ทันที ให้รอจังหวะที่เหมาะสม (เช่น หลัง user ใช้งานสักพัก)." \
  "seed" '["pwa","install"]'

save_memory "fact" "pwa-push-notification" \
  "Push Notification flow: (1) ขอ permission ด้วย Notification.requestPermission() - ต้องมี user gesture. (2) Subscribe ด้วย pushManager.subscribe() พร้อม applicationServerKey (VAPID). (3) ส่ง subscription ไป backend เก็บ. (4) Backend ใช้ web-push library ส่ง push. (5) Service worker รับใน push event แล้วแสดง notification. (6) Handle notificationclick event เพื่อเปิด app." \
  "seed" '["pwa","push","notification"]'

save_memory "fact" "pwa-lighthouse-checklist" \
  "Lighthouse PWA checklist: (1) Registers service worker. (2) Responds 200 when offline. (3) Has manifest with installable properties. (4) Redirects HTTP to HTTPS. (5) Configured for custom splash screen. (6) Sets theme color. (7) Content sized to viewport. (8) Has apple-touch-icon. Performance targets: LCP < 2.5s, FID < 100ms, CLS < 0.1, TTI < 3.8s." \
  "seed" '["pwa","lighthouse","performance"]'

save_memory "fact" "pwa-vite-plugin" \
  "vite-plugin-pwa (VitePWA) ช่วยสร้าง PWA กับ Vite: generateSW mode สร้าง service worker อัตโนมัติ, injectManifest mode ให้เขียน SW เอง. ตั้งค่าใน vite.config.ts ด้วย VitePWA plugin. รองรับ auto-update, prompt update, และ manual update strategies. ใช้คู่กับ workbox-* packages." \
  "seed" '["pwa","vite","workbox"]'

# ===========================================
# Snippets - โค้ดที่ใช้ซ้ำได้
# ===========================================
echo "[snippets] Code patterns..."

save_memory "snippet" "pwa-manifest-json" \
'{
  "name": "App Name - Description",
  "short_name": "AppName",
  "id": "/",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#4f46e5",
  "orientation": "any",
  "categories": ["productivity"],
  "description": "A brief description of the app",
  "icons": [
    { "src": "/icons/icon-192x192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512x512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/icon-maskable.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ],
  "screenshots": [
    { "src": "/screenshots/desktop.png", "sizes": "1280x720", "type": "image/png", "form_factor": "wide" },
    { "src": "/screenshots/mobile.png", "sizes": "390x844", "type": "image/png", "form_factor": "narrow" }
  ]
}' \
  "seed" '["pwa","manifest","template"]'

save_memory "snippet" "pwa-vite-config" \
'// vite.config.ts
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: "prompt",        // แสดง prompt เมื่อมี update
      includeAssets: ["favicon.ico", "icons/*.png"],
      manifest: false,               // ใช้ manifest.json ใน public/ แทน
      workbox: {
        globPatterns: ["**/*.{js,css,html,ico,png,svg,woff2}"],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/api\..*/i,
            handler: "NetworkFirst",
            options: {
              cacheName: "api-cache",
              expiration: { maxEntries: 50, maxAgeSeconds: 300 },
              networkTimeoutSeconds: 3,
            },
          },
          {
            urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp)$/,
            handler: "CacheFirst",
            options: {
              cacheName: "image-cache",
              expiration: { maxEntries: 100, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
        ],
      },
    }),
  ],
});' \
  "seed" '["pwa","vite","config","workbox"]'

save_memory "snippet" "pwa-hook-install-prompt" \
'// hooks/useInstallPrompt.ts
import { useState, useEffect } from "react";

interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
}

export function useInstallPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [isInstallable, setIsInstallable] = useState(false);
  const [isInstalled, setIsInstalled] = useState(false);

  useEffect(() => {
    // เช็คว่า install แล้วหรือยัง
    if (window.matchMedia("(display-mode: standalone)").matches) {
      setIsInstalled(true);
      return;
    }

    const handler = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
      setIsInstallable(true);
    };

    window.addEventListener("beforeinstallprompt", handler);
    window.addEventListener("appinstalled", () => {
      setIsInstalled(true);
      setIsInstallable(false);
      setDeferredPrompt(null);
    });

    return () => window.removeEventListener("beforeinstallprompt", handler);
  }, []);

  const install = async () => {
    if (!deferredPrompt) return false;
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    setDeferredPrompt(null);
    setIsInstallable(false);
    return outcome === "accepted";
  };

  return { isInstallable, isInstalled, install };
}' \
  "seed" '["pwa","hook","install","react"]'

save_memory "snippet" "pwa-hook-online-status" \
'// hooks/useOnlineStatus.ts
import { useSyncExternalStore } from "react";

function subscribe(callback: () => void) {
  window.addEventListener("online", callback);
  window.addEventListener("offline", callback);
  return () => {
    window.removeEventListener("online", callback);
    window.removeEventListener("offline", callback);
  };
}

export function useOnlineStatus(): boolean {
  return useSyncExternalStore(
    subscribe,
    () => navigator.onLine,       // client
    () => true                    // server (SSR)
  );
}' \
  "seed" '["pwa","hook","online","react"]'

save_memory "snippet" "pwa-hook-push-notification" \
'// hooks/usePushNotification.ts
import { useState, useCallback } from "react";

const VAPID_PUBLIC_KEY = import.meta.env.VITE_VAPID_PUBLIC_KEY;

function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const raw = atob(base64);
  return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)));
}

export function usePushNotification() {
  const [permission, setPermission] = useState(Notification.permission);
  const [subscription, setSubscription] = useState<PushSubscription | null>(null);

  const subscribe = useCallback(async () => {
    const perm = await Notification.requestPermission();
    setPermission(perm);
    if (perm !== "granted") return null;

    const reg = await navigator.serviceWorker.ready;
    const sub = await reg.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY),
    });
    setSubscription(sub);

    // ส่ง subscription ไป backend
    await fetch("/api/push/subscribe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(sub.toJSON()),
    });

    return sub;
  }, []);

  return { permission, subscription, subscribe };
}' \
  "seed" '["pwa","hook","push","notification","react"]'

save_memory "snippet" "pwa-indexeddb-wrapper" \
'// lib/db.ts
import { openDB, type DBSchema, type IDBPDatabase } from "idb";

interface AppDB extends DBSchema {
  tasks: {
    key: string;
    value: {
      id: string;
      title: string;
      completed: boolean;
      synced: boolean;
      updatedAt: number;
    };
    indexes: { "by-synced": "synced" };
  };
  pendingActions: {
    key: number;
    value: {
      url: string;
      method: string;
      body: string;
      createdAt: number;
    };
  };
}

let dbInstance: IDBPDatabase<AppDB> | null = null;

export async function getDB(): Promise<IDBPDatabase<AppDB>> {
  if (dbInstance) return dbInstance;

  dbInstance = await openDB<AppDB>("app-db", 1, {
    upgrade(db) {
      const taskStore = db.createObjectStore("tasks", { keyPath: "id" });
      taskStore.createIndex("by-synced", "synced");
      db.createObjectStore("pendingActions", { autoIncrement: true });
    },
  });

  return dbInstance;
}

// ตัวอย่างการใช้งาน
export async function saveTask(task: AppDB["tasks"]["value"]) {
  const db = await getDB();
  await db.put("tasks", { ...task, updatedAt: Date.now() });
}

export async function getUnsyncedTasks() {
  const db = await getDB();
  return db.getAllFromIndex("tasks", "by-synced", false);
}

export async function queueAction(url: string, method: string, body: object) {
  const db = await getDB();
  await db.add("pendingActions", {
    url,
    method,
    body: JSON.stringify(body),
    createdAt: Date.now(),
  });
}' \
  "seed" '["pwa","indexeddb","offline","storage"]'

save_memory "snippet" "pwa-sw-background-sync" \
'// ใน service worker: background sync handler
// ใช้คู่กับ Workbox BackgroundSyncPlugin หรือเขียนเอง

import { BackgroundSyncPlugin } from "workbox-background-sync";
import { registerRoute } from "workbox-routing";
import { NetworkOnly } from "workbox-strategies";

// Queue สำหรับ API mutations ที่ fail ขณะ offline
const bgSyncPlugin = new BackgroundSyncPlugin("api-mutations-queue", {
  maxRetentionTime: 24 * 60, // retry ภายใน 24 ชม.
  onSync: async ({ queue }) => {
    let entry;
    while ((entry = await queue.shiftRequest())) {
      try {
        await fetch(entry.request);
      } catch (err) {
        await queue.unshiftRequest(entry);
        throw err;
      }
    }
  },
});

// ใช้กับ POST/PUT/DELETE requests ไปยัง API
registerRoute(
  ({ url, request }) =>
    url.pathname.startsWith("/api/") && request.method !== "GET",
  new NetworkOnly({ plugins: [bgSyncPlugin] }),
  "POST"
);' \
  "seed" '["pwa","background-sync","workbox","offline"]'

save_memory "snippet" "pwa-update-prompt-component" \
'// components/UpdatePrompt.tsx
import { useRegisterSW } from "virtual:pwa-register/react";

export function UpdatePrompt() {
  const {
    needRefresh: [needRefresh],
    updateServiceWorker,
  } = useRegisterSW();

  if (!needRefresh) return null;

  return (
    <div className="fixed bottom-4 left-4 right-4 z-50 flex items-center
                    justify-between rounded-lg bg-indigo-600 px-4 py-3
                    text-white shadow-lg sm:left-auto sm:right-4 sm:w-96">
      <p className="text-sm font-medium">มีเวอร์ชันใหม่พร้อมใช้งาน</p>
      <div className="flex gap-2">
        <button
          onClick={() => updateServiceWorker(true)}
          className="rounded bg-white px-3 py-1 text-sm font-semibold text-indigo-600
                     hover:bg-indigo-50"
        >
          อัปเดต
        </button>
      </div>
    </div>
  );
}' \
  "seed" '["pwa","update","prompt","react","component"]'

# ===========================================
# Feedback - ข้อตกลงของทีม
# ===========================================
echo "[feedback] Team preferences..."

save_memory "feedback" "pwa-offline-first" \
  "ออกแบบ offline-first เสมอ ไม่ใช่ offline-as-fallback. Why: user อาจอยู่ในที่ที่ signal ไม่ดี ต้องใช้งานได้โดยไม่ต้องพึ่ง network. How to apply: เก็บ data ใน IndexedDB ก่อน แล้ว sync ทีหลัง ไม่ใช่เรียก API แล้ว fallback cache." \
  "seed" '["pwa","offline","design"]'

save_memory "feedback" "pwa-no-localstorage" \
  "ห้ามใช้ localStorage สำหรับ app data ใช้ IndexedDB แทน. Why: localStorage เป็น sync API, มี size limit 5-10MB, ไม่รองรับ structured data. How to apply: ใช้ idb หรือ Dexie.js wrapper เสมอ localStorage ใช้ได้แค่ simple flags เช่น theme preference." \
  "seed" '["pwa","storage","indexeddb"]'

save_memory "feedback" "pwa-test-offline" \
  "ทุก feature ต้องทดสอบใน offline mode ด้วย. Why: หลายครั้ง feature ทำงานดีตอน online แต่พังเมื่อ offline. How to apply: ใช้ Chrome DevTools → Application → Service Workers → Offline checkbox ทดสอบทุกครั้ง." \
  "seed" '["pwa","testing","offline"]'

save_memory "feedback" "pwa-lighthouse-ci" \
  "รัน Lighthouse CI ใน pipeline ทุก PR ตั้ง budget: Performance >= 90, PWA >= 90. Why: ป้องกัน regression. How to apply: ใช้ @lhci/cli ใน CI/CD pipeline พร้อม assertion config." \
  "seed" '["pwa","lighthouse","ci","performance"]'

echo ""
echo "============================================"
echo "  Done! Seeded $(curl -s $MEMORY_URL/health | jq '.memories | to_entries | map(.value) | add') memories"
echo "============================================"
echo ""
echo "  View all: curl $MEMORY_URL/memories"
echo "  Copy agent: cp examples/pwa-dev/pwa-agent.md .opencode/agents/"
echo ""
