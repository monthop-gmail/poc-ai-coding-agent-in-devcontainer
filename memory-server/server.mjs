/**
 * Global Memory MCP Server
 *
 * Provides persistent, team-shared memory for OpenCode agents.
 * Backed by Redis for durability across container restarts.
 *
 * Memory Types:
 *   - fact:     Project facts, architecture decisions, conventions
 *   - feedback: User preferences, corrections, confirmed approaches
 *   - context:  Current work context, goals, blockers
 *   - snippet:  Reusable code patterns, templates
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import Redis from "ioredis";
import { createServer } from "http";

// ===========================================
// Redis Connection
// ===========================================
const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";
const NAMESPACE = process.env.MEMORY_NAMESPACE || "default-team";
const MCP_PORT = parseInt(process.env.MCP_PORT || "3100");

const redis = new Redis(REDIS_URL, {
  retryStrategy: (times) => Math.min(times * 200, 5000),
  maxRetriesPerRequest: 3,
});

redis.on("connect", () => console.log(`[memory] Connected to Redis`));
redis.on("error", (err) => console.error(`[memory] Redis error:`, err.message));

// ===========================================
// Memory Helpers
// ===========================================
const key = (type, id) => `memory:${NAMESPACE}:${type}:${id}`;
const indexKey = (type) => `memory:${NAMESPACE}:index:${type}`;
const allIndexKey = () => `memory:${NAMESPACE}:index:all`;

async function saveMemory(type, id, content, metadata = {}) {
  const entry = {
    id,
    type,
    content,
    metadata: JSON.stringify(metadata),
    created_by: metadata.author || "unknown",
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  const existingRaw = await redis.hgetall(key(type, id));
  if (existingRaw && existingRaw.created_at) {
    entry.created_at = existingRaw.created_at;
  }

  await redis.hset(key(type, id), entry);
  await redis.sadd(indexKey(type), id);
  await redis.sadd(allIndexKey(), `${type}:${id}`);

  return entry;
}

async function getMemory(type, id) {
  const data = await redis.hgetall(key(type, id));
  if (!data || !data.id) return null;
  data.metadata = JSON.parse(data.metadata || "{}");
  return data;
}

async function listMemories(type) {
  const ids = await redis.smembers(indexKey(type));
  const results = [];
  for (const id of ids) {
    const mem = await getMemory(type, id);
    if (mem) results.push(mem);
  }
  return results.sort(
    (a, b) => new Date(b.updated_at) - new Date(a.updated_at)
  );
}

async function searchMemories(query, type = null) {
  const queryLower = query.toLowerCase();
  const types = type ? [type] : ["fact", "feedback", "context", "snippet"];
  const results = [];

  for (const t of types) {
    const memories = await listMemories(t);
    for (const mem of memories) {
      const searchable =
        `${mem.id} ${mem.content} ${JSON.stringify(mem.metadata)}`.toLowerCase();
      if (searchable.includes(queryLower)) {
        results.push(mem);
      }
    }
  }

  return results;
}

async function deleteMemory(type, id) {
  await redis.del(key(type, id));
  await redis.srem(indexKey(type), id);
  await redis.srem(allIndexKey(), `${type}:${id}`);
}

async function getAllMemorySummary() {
  const types = ["fact", "feedback", "context", "snippet"];
  const summary = {};
  for (const t of types) {
    const count = await redis.scard(indexKey(t));
    summary[t] = count;
  }
  return summary;
}

// ===========================================
// MCP Server
// ===========================================
const server = new Server(
  { name: "global-memory", version: "1.0.0" },
  { capabilities: { tools: {}, resources: {} } }
);

// --- Tools ---
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "memory_save",
      description:
        "Save a memory entry to global team memory. Use this to persist important facts, decisions, feedback, context, or code snippets that should be shared across all team agents and sessions.",
      inputSchema: {
        type: "object",
        properties: {
          type: {
            type: "string",
            enum: ["fact", "feedback", "context", "snippet"],
            description:
              "Memory type: fact (decisions/conventions), feedback (user preferences), context (current work), snippet (code patterns)",
          },
          id: {
            type: "string",
            description:
              "Unique identifier for this memory (e.g., 'auth-pattern', 'deploy-process')",
          },
          content: {
            type: "string",
            description: "The memory content to store",
          },
          metadata: {
            type: "object",
            description:
              "Optional metadata (author, tags, project, priority)",
            properties: {
              author: { type: "string" },
              tags: { type: "array", items: { type: "string" } },
              project: { type: "string" },
              priority: {
                type: "string",
                enum: ["low", "medium", "high"],
              },
            },
          },
        },
        required: ["type", "id", "content"],
      },
    },
    {
      name: "memory_get",
      description: "Retrieve a specific memory entry by type and id.",
      inputSchema: {
        type: "object",
        properties: {
          type: {
            type: "string",
            enum: ["fact", "feedback", "context", "snippet"],
          },
          id: { type: "string" },
        },
        required: ["type", "id"],
      },
    },
    {
      name: "memory_search",
      description:
        "Search team memories by keyword. Returns matching memories across all types or filtered by type.",
      inputSchema: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description: "Search keyword or phrase",
          },
          type: {
            type: "string",
            enum: ["fact", "feedback", "context", "snippet"],
            description: "Optional: filter by memory type",
          },
        },
        required: ["query"],
      },
    },
    {
      name: "memory_list",
      description:
        "List all memories of a specific type, sorted by most recently updated.",
      inputSchema: {
        type: "object",
        properties: {
          type: {
            type: "string",
            enum: ["fact", "feedback", "context", "snippet"],
          },
        },
        required: ["type"],
      },
    },
    {
      name: "memory_delete",
      description: "Delete a memory entry.",
      inputSchema: {
        type: "object",
        properties: {
          type: {
            type: "string",
            enum: ["fact", "feedback", "context", "snippet"],
          },
          id: { type: "string" },
        },
        required: ["type", "id"],
      },
    },
    {
      name: "memory_summary",
      description:
        "Get a summary of all stored memories (counts by type). Use this to understand what the team has stored.",
      inputSchema: {
        type: "object",
        properties: {},
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "memory_save": {
        const entry = await saveMemory(
          args.type,
          args.id,
          args.content,
          args.metadata || {}
        );
        return {
          content: [
            {
              type: "text",
              text: `Saved memory [${entry.type}/${entry.id}] at ${entry.updated_at}`,
            },
          ],
        };
      }

      case "memory_get": {
        const mem = await getMemory(args.type, args.id);
        if (!mem)
          return {
            content: [
              {
                type: "text",
                text: `Memory [${args.type}/${args.id}] not found`,
              },
            ],
          };
        return {
          content: [{ type: "text", text: JSON.stringify(mem, null, 2) }],
        };
      }

      case "memory_search": {
        const results = await searchMemories(args.query, args.type);
        return {
          content: [
            {
              type: "text",
              text:
                results.length > 0
                  ? JSON.stringify(results, null, 2)
                  : `No memories found matching "${args.query}"`,
            },
          ],
        };
      }

      case "memory_list": {
        const list = await listMemories(args.type);
        return {
          content: [
            {
              type: "text",
              text:
                list.length > 0
                  ? JSON.stringify(list, null, 2)
                  : `No memories of type "${args.type}"`,
            },
          ],
        };
      }

      case "memory_delete": {
        await deleteMemory(args.type, args.id);
        return {
          content: [
            {
              type: "text",
              text: `Deleted memory [${args.type}/${args.id}]`,
            },
          ],
        };
      }

      case "memory_summary": {
        const summary = await getAllMemorySummary();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                { namespace: NAMESPACE, counts: summary },
                null,
                2
              ),
            },
          ],
        };
      }

      default:
        return {
          content: [{ type: "text", text: `Unknown tool: ${name}` }],
          isError: true,
        };
    }
  } catch (error) {
    return {
      content: [{ type: "text", text: `Error: ${error.message}` }],
      isError: true,
    };
  }
});

// --- Resources (memory as readable resources) ---
server.setRequestHandler(ListResourcesRequestSchema, async () => ({
  resources: [
    {
      uri: "memory://summary",
      name: "Memory Summary",
      description: "Overview of all team memories",
      mimeType: "application/json",
    },
    {
      uri: "memory://facts",
      name: "All Facts",
      description: "Project facts and decisions",
      mimeType: "application/json",
    },
    {
      uri: "memory://feedback",
      name: "All Feedback",
      description: "Team feedback and preferences",
      mimeType: "application/json",
    },
  ],
}));

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const { uri } = request.params;

  if (uri === "memory://summary") {
    const summary = await getAllMemorySummary();
    return {
      contents: [
        {
          uri,
          mimeType: "application/json",
          text: JSON.stringify({ namespace: NAMESPACE, counts: summary }, null, 2),
        },
      ],
    };
  }

  const typeMatch = uri.match(/^memory:\/\/(\w+)$/);
  if (typeMatch) {
    const list = await listMemories(typeMatch[1]);
    return {
      contents: [
        {
          uri,
          mimeType: "application/json",
          text: JSON.stringify(list, null, 2),
        },
      ],
    };
  }

  throw new Error(`Unknown resource: ${uri}`);
});

// ===========================================
// Start Server (HTTP + MCP Stdio)
// ===========================================
const mode = process.env.MCP_MODE || "http";

if (mode === "stdio") {
  // Stdio mode for direct MCP integration
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.log("[memory] MCP server running on stdio");
} else {
  // HTTP mode for remote/docker access
  const httpServer = createServer(async (req, res) => {
    // Health check
    if (req.method === "GET" && req.url === "/health") {
      const redisOk = redis.status === "ready";
      const summary = await getAllMemorySummary();
      res.writeHead(redisOk ? 200 : 503, {
        "Content-Type": "application/json",
      });
      res.end(
        JSON.stringify({
          status: redisOk ? "healthy" : "unhealthy",
          redis: redis.status,
          namespace: NAMESPACE,
          memories: summary,
        })
      );
      return;
    }

    // REST API for tools
    if (req.method === "POST" && req.url === "/mcp") {
      let body = "";
      req.on("data", (chunk) => (body += chunk));
      req.on("end", async () => {
        try {
          const rpcRequest = JSON.parse(body);
          const { name, arguments: args } = rpcRequest.params || {};
          let result;

          switch (name) {
            case "memory_save":
              result = await saveMemory(args.type, args.id, args.content, args.metadata || {});
              result = { content: [{ type: "text", text: `Saved memory [${result.type}/${result.id}] at ${result.updated_at}` }] };
              break;
            case "memory_get":
              result = await getMemory(args.type, args.id);
              result = { content: [{ type: "text", text: result ? JSON.stringify(result, null, 2) : `Not found: ${args.type}/${args.id}` }] };
              break;
            case "memory_search":
              result = await searchMemories(args.query, args.type);
              result = { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
              break;
            case "memory_list":
              result = await listMemories(args.type);
              result = { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
              break;
            case "memory_delete":
              await deleteMemory(args.type, args.id);
              result = { content: [{ type: "text", text: `Deleted [${args.type}/${args.id}]` }] };
              break;
            case "memory_summary":
              result = await getAllMemorySummary();
              result = { content: [{ type: "text", text: JSON.stringify({ namespace: NAMESPACE, counts: result }, null, 2) }] };
              break;
            default:
              result = { error: `Unknown tool: ${name}` };
          }

          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify(result));
        } catch (err) {
          res.writeHead(400, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: err.message }));
        }
      });
      return;
    }

    // API shortcuts
    if (req.method === "GET" && req.url === "/memories") {
      const summary = await getAllMemorySummary();
      const all = {};
      for (const type of ["fact", "feedback", "context", "snippet"]) {
        all[type] = await listMemories(type);
      }
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ summary, memories: all }, null, 2));
      return;
    }

    res.writeHead(404);
    res.end("Not found");
  });

  httpServer.listen(MCP_PORT, "0.0.0.0", () => {
    console.log(`[memory] HTTP server on port ${MCP_PORT}`);
    console.log(`[memory] Health: http://localhost:${MCP_PORT}/health`);
    console.log(`[memory] MCP endpoint: http://localhost:${MCP_PORT}/mcp`);
    console.log(`[memory] Browse: http://localhost:${MCP_PORT}/memories`);
    console.log(`[memory] Namespace: ${NAMESPACE}`);
  });
}
