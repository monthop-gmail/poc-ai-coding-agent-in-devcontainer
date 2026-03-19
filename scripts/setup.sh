#!/bin/bash
set -e

echo "============================================"
echo "  Setting up OpenCode Agent Environment"
echo "============================================"

# Install memory server dependencies (for stdio mode)
if [ -d "/workspace/memory-server" ]; then
  echo "[setup] Installing memory server dependencies..."
  cd /workspace/memory-server && npm install --production
  cd /workspace
fi

# Verify opencode is installed
if command -v opencode &> /dev/null; then
  echo "[setup] OpenCode version: $(opencode --version 2>/dev/null || echo 'installed')"
else
  echo "[setup] Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
fi

# Wait for Redis to be ready
echo "[setup] Waiting for Redis..."
for i in {1..30}; do
  if redis-cli -h redis -p 6379 ping 2>/dev/null | grep -q PONG; then
    echo "[setup] Redis is ready!"
    break
  fi
  sleep 1
done

# Wait for memory server
echo "[setup] Waiting for memory server..."
for i in {1..30}; do
  if curl -sf http://memory:3100/health > /dev/null 2>&1; then
    echo "[setup] Memory server is ready!"
    break
  fi
  sleep 1
done

# Show status
echo ""
echo "============================================"
echo "  Environment Ready!"
echo "============================================"
echo ""
echo "  OpenCode:  Run 'opencode' to start"
echo "  Memory:    http://localhost:3100/health"
echo "  Memories:  http://localhost:3100/memories"
echo ""
echo "  Agents available:"
echo "    @coder    - Full-stack coding with memory"
echo "    @reviewer - Code review against team standards"
echo ""
echo "  Memory commands in OpenCode:"
echo "    memory_save    - Store team knowledge"
echo "    memory_search  - Find relevant memories"
echo "    memory_list    - List memories by type"
echo "    memory_summary - Overview of stored memories"
echo ""
echo "============================================"
