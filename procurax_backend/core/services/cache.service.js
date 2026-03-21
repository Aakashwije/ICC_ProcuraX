/**
 * Cache Service — Redis-Backed with In-Memory Fallback
 *
 * Provides a unified caching API that works with both Redis (production /
 * horizontal scaling) and an in-memory Map (development / single instance).
 *
 * The CacheService delegates storage to the RedisService client.
 * When REDIS_URL is set, all cache operations go through Redis so
 * multiple Node.js processes share the same cache. When Redis is
 * unavailable, the service automatically falls back to a local Map.
 *
 * Architecture:
 *   CacheService
 *     ├── get / set / delete / invalidatePrefix
 *     ├── middleware()  → Express GET response caching
 *     └── RedisService.client  (ioredis | InMemoryRedisClient)
 *
 * Horizontal Scaling:
 *   All instances share cache via Redis → consistent reads after writes.
 */

import logger from "../logging/logger.js";
import redisService from "./redis.service.js";

class CacheService {
  constructor() {
    this._stats = { hits: 0, misses: 0, sets: 0, evictions: 0 };
    this._defaultTTL = 300; // 5 minutes
  }

  // ─── helpers ────────────────────────────────────────────────────────

  /** @private Serialise any JS value for Redis storage */
  _serialise(value) {
    return JSON.stringify(value);
  }

  /** @private Deserialise a Redis string back to a JS value */
  _deserialise(raw) {
    if (raw === null || raw === undefined) return null;
    try {
      return JSON.parse(raw);
    } catch {
      return raw;
    }
  }

  // ─── public API ────────────────────────────────────────────────────

  /**
   * Get a value from cache.
   * @param {string} key
   * @returns {Promise<*>} cached value or null
   */
  async get(key) {
    try {
      const raw = await redisService.client.get(`cache:${key}`);
      if (raw === null) {
        this._stats.misses++;
        return null;
      }
      this._stats.hits++;
      return this._deserialise(raw);
    } catch (err) {
      logger.warn("Cache GET error", { key, error: err.message });
      this._stats.misses++;
      return null;
    }
  }

  /**
   * Set a value in cache with TTL.
   * @param {string} key
   * @param {*} value
   * @param {number} ttlSeconds — default 300 (5 min)
   */
  async set(key, value, ttlSeconds = this._defaultTTL) {
    try {
      await redisService.client.set(
        `cache:${key}`,
        this._serialise(value),
        "EX",
        ttlSeconds
      );
      this._stats.sets++;
    } catch (err) {
      logger.warn("Cache SET error", { key, error: err.message });
    }
  }

  /**
   * Delete a specific key.
   */
  async delete(key) {
    try {
      return await redisService.client.del(`cache:${key}`);
    } catch (err) {
      logger.warn("Cache DELETE error", { key, error: err.message });
      return 0;
    }
  }

  /**
   * Invalidate all keys matching a prefix.
   * E.g., invalidatePrefix("tasks:user123") clears all task cache for that user.
   */
  async invalidatePrefix(prefix) {
    try {
      const keys = await redisService.client.keys(`cache:${prefix}*`);
      if (keys.length > 0) {
        await redisService.client.del(...keys);
        this._stats.evictions += keys.length;
        logger.debug(`Cache invalidated ${keys.length} keys with prefix: ${prefix}`);
      }
      return keys.length;
    } catch (err) {
      logger.warn("Cache INVALIDATE error", { prefix, error: err.message });
      return 0;
    }
  }

  /**
   * Clear entire cache namespace.
   */
  async clear() {
    try {
      const keys = await redisService.client.keys("cache:*");
      if (keys.length > 0) {
        await redisService.client.del(...keys);
      }
      logger.info(`Cache cleared, ${keys.length} entries removed`);
      return keys.length;
    } catch (err) {
      logger.warn("Cache CLEAR error", { error: err.message });
      return 0;
    }
  }

  /**
   * Get cache statistics.
   */
  getStats() {
    const total = this._stats.hits + this._stats.misses;
    const hitRate = total > 0
      ? ((this._stats.hits / total) * 100).toFixed(1)
      : 0;

    // Attempt to get the number of cached entries (sync-safe estimate)
    let size = 0;
    try {
      // For in-memory client the _store Map is accessible synchronously
      const client = redisService._client;
      if (client && client._store instanceof Map) {
        for (const k of client._store.keys()) {
          if (k.startsWith("cache:")) size++;
        }
      }
    } catch {
      // Ignore — size is best-effort
    }

    return {
      ...this._stats,
      size,
      hitRate: `${hitRate}%`,
      backend: redisService.isRedis ? "redis" : "in-memory",
    };
  }

  /**
   * Express middleware for caching GET responses.
   * @param {number} ttlSeconds — cache duration
   * @param {Function} keyFn — optional function to generate cache key from req
   */
  middleware(ttlSeconds = 60, keyFn = null) {
    return async (req, res, next) => {
      if (req.method !== "GET") return next();

      const key = keyFn
        ? keyFn(req)
        : `route:${req.originalUrl}:${req.userId || "anon"}`;

      try {
        const cached = await this.get(key);
        if (cached) {
          logger.debug("Cache HIT (middleware)", { key });
          return res.json(cached);
        }
      } catch {
        // Cache read failed — proceed without cache
      }

      // Intercept res.json to cache the response
      const originalJson = res.json.bind(res);
      res.json = (body) => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          this.set(key, body, ttlSeconds).catch(() => {});
        }
        return originalJson(body);
      };

      next();
    };
  }

  /**
   * Shutdown — no interval to clear when using Redis.
   */
  async shutdown() {
    logger.info("CacheService shutdown complete");
  }
}

// Singleton instance
const cache = new CacheService();

export default cache;
