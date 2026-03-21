/**
 * Redis Service
 *
 * Provides a shared Redis client for cache, sessions, rate limiting,
 * and the Bull job queue. Falls back to in-memory adapters when no
 * REDIS_URL is configured (development / single-instance deployments).
 *
 * Architecture:
 *   ┌───────────────────────────┐
 *   │    RedisService           │
 *   │  ┌─────────────────────┐  │
 *   │  │  IoRedis client     │  │  ← production (REDIS_URL set)
 *   │  └─────────────────────┘  │
 *   │  ┌─────────────────────┐  │
 *   │  │  In-memory fallback │  │  ← development (no Redis)
 *   │  └─────────────────────┘  │
 *   └───────────────────────────┘
 *
 * Horizontal Scaling:
 *   When multiple Node.js instances run behind a load balancer,
 *   all share the same Redis instance so cache, rate-limit counters,
 *   and queued jobs are consistent across processes.
 */

import logger from "../logging/logger.js";

// ─── In-memory fallback (mimics a subset of the ioredis API) ────────
class InMemoryRedisClient {
  constructor() {
    this._store = new Map();
    this._connected = true;
    this._subscribers = new Map();
    logger.info("Redis fallback: using in-memory store (single-instance only)");
  }

  async get(key) {
    const entry = this._store.get(key);
    if (!entry) return null;
    if (entry.expiresAt && entry.expiresAt < Date.now()) {
      this._store.delete(key);
      return null;
    }
    return entry.value;
  }

  async set(key, value, ...args) {
    const entry = { value };
    // Handle: set(key, value, "EX", seconds)
    if (args[0] === "EX" && typeof args[1] === "number") {
      entry.expiresAt = Date.now() + args[1] * 1000;
    }
    // Handle: set(key, value, "PX", milliseconds)
    if (args[0] === "PX" && typeof args[1] === "number") {
      entry.expiresAt = Date.now() + args[1];
    }
    this._store.set(key, entry);
    return "OK";
  }

  async del(...keys) {
    let count = 0;
    for (const key of keys) {
      if (this._store.delete(key)) count++;
    }
    return count;
  }

  async keys(pattern) {
    const prefix = pattern.replace("*", "");
    return [...this._store.keys()].filter((k) => k.startsWith(prefix));
  }

  async flushdb() {
    this._store.clear();
    return "OK";
  }

  async incr(key) {
    const entry = this._store.get(key);
    const current = entry ? parseInt(entry.value, 10) || 0 : 0;
    const next = current + 1;
    if (entry) {
      entry.value = String(next);
    } else {
      this._store.set(key, { value: String(next) });
    }
    return next;
  }

  async expire(key, seconds) {
    const entry = this._store.get(key);
    if (entry) {
      entry.expiresAt = Date.now() + seconds * 1000;
      return 1;
    }
    return 0;
  }

  async ttl(key) {
    const entry = this._store.get(key);
    if (!entry) return -2;
    if (!entry.expiresAt) return -1;
    return Math.max(0, Math.ceil((entry.expiresAt - Date.now()) / 1000));
  }

  async ping() {
    return "PONG";
  }

  get status() {
    return this._connected ? "ready" : "end";
  }

  async quit() {
    this._connected = false;
    this._store.clear();
    return "OK";
  }

  async disconnect() {
    return this.quit();
  }

  // Pub/Sub stubs for Bull compatibility
  duplicate() {
    return new InMemoryRedisClient();
  }

  on(event, handler) {
    if (!this._subscribers.has(event)) {
      this._subscribers.set(event, []);
    }
    this._subscribers.get(event).push(handler);
    // Emit "ready" immediately for in-memory
    if (event === "ready") {
      setTimeout(() => handler(), 0);
    }
    return this;
  }
}

// ─── Redis Service singleton ────────────────────────────────────────
class RedisService {
  constructor() {
    this._client = null;
    this._isRedis = false;
    this._connectionRetries = 0;
    this._maxRetries = 5;
  }

  /**
   * Initialise the Redis connection (or in-memory fallback).
   * Call once at app startup.
   */
  async connect() {
    const redisUrl = process.env.REDIS_URL || process.env.REDIS_URI;

    if (redisUrl) {
      try {
        // Dynamic import so the app still works without ioredis installed
        const Redis = (await import("ioredis")).default;

        this._client = new Redis(redisUrl, {
          maxRetriesPerRequest: 3,
          retryStrategy: (times) => {
            this._connectionRetries = times;
            if (times > this._maxRetries) {
              logger.error("Redis max retries reached — falling back to in-memory");
              this._client = new InMemoryRedisClient();
              this._isRedis = false;
              return null; // stop retrying
            }
            const delay = Math.min(times * 200, 5000);
            logger.warn(`Redis retry #${times} in ${delay}ms`);
            return delay;
          },
          lazyConnect: true,
          enableReadyCheck: true,
          connectTimeout: 10_000,
        });

        await this._client.connect();
        this._isRedis = true;
        logger.info("✅ Redis connected", { url: redisUrl.replace(/\/\/.*@/, "//***@") });

        this._client.on("error", (err) => {
          logger.error("Redis connection error", { error: err.message });
        });

        this._client.on("close", () => {
          logger.warn("Redis connection closed");
        });

        this._client.on("reconnecting", () => {
          logger.info("Redis reconnecting…");
        });
      } catch (err) {
        logger.warn("Redis unavailable — falling back to in-memory", {
          error: err.message,
        });
        this._client = new InMemoryRedisClient();
        this._isRedis = false;
      }
    } else {
      logger.info("No REDIS_URL configured — using in-memory store");
      this._client = new InMemoryRedisClient();
      this._isRedis = false;
    }

    return this._client;
  }

  /** Raw ioredis (or in-memory) client */
  get client() {
    if (!this._client) {
      throw new Error("RedisService not initialised — call connect() first");
    }
    return this._client;
  }

  /** Whether we're backed by real Redis */
  get isRedis() {
    return this._isRedis;
  }

  /** Connection health check */
  async ping() {
    try {
      const result = await this._client.ping();
      return result === "PONG";
    } catch {
      return false;
    }
  }

  /** Graceful shutdown */
  async disconnect() {
    if (this._client) {
      await this._client.quit();
      logger.info("Redis disconnected");
    }
  }

  /**
   * Get connection status for health endpoints
   */
  getStatus() {
    return {
      connected: this._client?.status === "ready" || !this._isRedis,
      backend: this._isRedis ? "redis" : "in-memory",
      retries: this._connectionRetries,
    };
  }
}

// Singleton
const redisService = new RedisService();
export default redisService;
