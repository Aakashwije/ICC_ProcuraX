/**
 * Cache Service
 *
 * In-memory TTL cache for frequently accessed data.
 * Reduces database load for read-heavy endpoints.
 *
 * Design Decision: Using in-memory cache for single-instance deployments.
 * For horizontal scaling, replace with Redis to share cache across
 * multiple Node.js processes / containers.
 */

import logger from "../logging/logger.js";

class CacheService {
  constructor() {
    this._store = new Map();
    this._stats = { hits: 0, misses: 0, sets: 0, evictions: 0 };

    // Periodic cleanup of expired entries every 60 seconds
    this._cleanupInterval = setInterval(() => this._cleanup(), 60_000);
  }

  /**
   * Get a value from cache
   * @param {string} key
   * @returns {*} cached value or null
   */
  get(key) {
    const entry = this._store.get(key);

    if (!entry) {
      this._stats.misses++;
      return null;
    }

    if (entry.expiresAt && entry.expiresAt < Date.now()) {
      this._store.delete(key);
      this._stats.misses++;
      this._stats.evictions++;
      return null;
    }

    this._stats.hits++;
    return entry.value;
  }

  /**
   * Set a value in cache
   * @param {string} key
   * @param {*} value
   * @param {number} ttlSeconds - Time to live in seconds (default 300 = 5 min)
   */
  set(key, value, ttlSeconds = 300) {
    this._store.set(key, {
      value,
      expiresAt: Date.now() + ttlSeconds * 1000,
      createdAt: Date.now(),
    });
    this._stats.sets++;
  }

  /**
   * Delete a specific key
   */
  delete(key) {
    return this._store.delete(key);
  }

  /**
   * Invalidate all keys matching a prefix
   * E.g., invalidatePrefix("tasks:user123") clears all task cache for a user
   */
  invalidatePrefix(prefix) {
    let count = 0;
    for (const key of this._store.keys()) {
      if (key.startsWith(prefix)) {
        this._store.delete(key);
        count++;
      }
    }
    if (count > 0) {
      logger.debug(`Cache invalidated ${count} keys with prefix: ${prefix}`);
    }
    return count;
  }

  /**
   * Clear entire cache
   */
  clear() {
    const size = this._store.size;
    this._store.clear();
    logger.info(`Cache cleared, ${size} entries removed`);
    return size;
  }

  /**
   * Get cache statistics
   */
  getStats() {
    const hitRate =
      this._stats.hits + this._stats.misses > 0
        ? ((this._stats.hits / (this._stats.hits + this._stats.misses)) * 100).toFixed(1)
        : 0;

    return {
      ...this._stats,
      size: this._store.size,
      hitRate: `${hitRate}%`,
    };
  }

  /**
   * Express middleware for caching GET responses
   * @param {number} ttlSeconds - Cache duration
   * @param {Function} keyFn - Function to generate cache key from req
   */
  middleware(ttlSeconds = 60, keyFn = null) {
    return (req, res, next) => {
      if (req.method !== "GET") return next();

      const key = keyFn ? keyFn(req) : `route:${req.originalUrl}:${req.userId || "anon"}`;
      const cached = this.get(key);

      if (cached) {
        logger.debug("Cache HIT", { key });
        return res.json(cached);
      }

      // Intercept res.json to cache the response
      const originalJson = res.json.bind(res);
      res.json = (body) => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          this.set(key, body, ttlSeconds);
        }
        return originalJson(body);
      };

      next();
    };
  }

  /**
   * Cleanup expired entries
   */
  _cleanup() {
    const now = Date.now();
    let cleaned = 0;
    for (const [key, entry] of this._store.entries()) {
      if (entry.expiresAt && entry.expiresAt < now) {
        this._store.delete(key);
        cleaned++;
      }
    }
    if (cleaned > 0) {
      this._stats.evictions += cleaned;
      logger.debug(`Cache cleanup: ${cleaned} expired entries removed`);
    }
  }

  /**
   * Shutdown - clear interval
   */
  shutdown() {
    clearInterval(this._cleanupInterval);
    this._store.clear();
  }
}

// Singleton instance
const cache = new CacheService();

export default cache;
