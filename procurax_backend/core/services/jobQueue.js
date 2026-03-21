/**
 * Async Job Queue — Redis-Backed (Bull) with In-Process Fallback
 *
 * When REDIS_URL is configured, delegates to Bull for distributed,
 * persistent job processing across multiple Node.js instances.
 * Falls back to the in-process queue for development / single-instance.
 *
 * Horizontal Scaling:
 *   ┌────────────┐  ┌────────────┐
 *   │  Node #1   │  │  Node #2   │
 *   │  (worker)  │  │  (worker)  │
 *   └──────┬─────┘  └──────┬─────┘
 *          │               │
 *     ┌────▼───────────────▼────┐
 *     │     Redis (Bull queue)  │
 *     └─────────────────────────┘
 *
 * Both instances consume from the same queue — no duplicate processing.
 */

import logger from "../logging/logger.js";
import redisService from "./redis.service.js";

// ─── In-process fallback queue ──────────────────────────────────────
class InProcessQueue {
  constructor() {
    this._queue = [];
    this._processing = false;
    this._handlers = new Map();
    this._retryConfig = { maxRetries: 3, backoffMs: 1000 };
    this._stats = { enqueued: 0, processed: 0, failed: 0, retried: 0 };
  }

  registerHandler(jobType, handler) {
    this._handlers.set(jobType, handler);
    logger.info(`Job handler registered (in-process): ${jobType}`);
  }

  async enqueue(jobType, payload, options = {}) {
    const job = {
      id: `job_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`,
      type: jobType,
      payload,
      priority: options.priority || "normal",
      maxRetries: options.maxRetries ?? this._retryConfig.maxRetries,
      retryCount: 0,
      createdAt: new Date(),
      status: "pending",
    };

    if (options.delay) {
      setTimeout(() => {
        this._queue.push(job);
        this._processQueue();
      }, options.delay);
    } else {
      this._queue.push(job);
    }

    this._stats.enqueued++;
    logger.debug("Job enqueued (in-process)", { jobId: job.id, type: jobType });

    if (!this._processing) {
      this._processQueue();
    }
    return job.id;
  }

  async _processQueue() {
    if (this._processing || this._queue.length === 0) return;
    this._processing = true;

    while (this._queue.length > 0) {
      this._queue.sort((a, b) => {
        const order = { high: 0, normal: 1, low: 2 };
        return (order[a.priority] || 1) - (order[b.priority] || 1);
      });

      const job = this._queue.shift();
      const handler = this._handlers.get(job.type);

      if (!handler) {
        logger.warn(`No handler for job type: ${job.type}`, { jobId: job.id });
        this._stats.failed++;
        continue;
      }

      try {
        job.status = "processing";
        await handler(job.payload);
        job.status = "completed";
        this._stats.processed++;
        logger.debug("Job completed (in-process)", { jobId: job.id, type: job.type });
      } catch (err) {
        job.retryCount++;
        logger.error("Job failed (in-process)", {
          jobId: job.id,
          type: job.type,
          error: err.message,
          retryCount: job.retryCount,
        });

        if (job.retryCount < job.maxRetries) {
          const backoff = this._retryConfig.backoffMs * Math.pow(2, job.retryCount - 1);
          job.status = "pending";
          this._stats.retried++;
          setTimeout(() => {
            this._queue.push(job);
            this._processQueue();
          }, backoff);
        } else {
          job.status = "failed";
          this._stats.failed++;
          logger.error("Job permanently failed after max retries (in-process)", {
            jobId: job.id,
            type: job.type,
          });
        }
      }
    }
    this._processing = false;
  }

  getStats() {
    return {
      ...this._stats,
      pending: this._queue.length,
      registeredHandlers: [...this._handlers.keys()],
      backend: "in-process",
    };
  }

  clear() {
    const count = this._queue.length;
    this._queue = [];
    logger.info(`Job queue cleared (in-process), ${count} jobs removed`);
    return count;
  }

  async shutdown() {
    this._queue = [];
  }
}

// ─── Unified JobQueue wrapper ───────────────────────────────────────
class JobQueue {
  constructor() {
    this._backend = null;
    this._bullQueues = new Map();
    this._handlers = new Map();
    this._isBull = false;
  }

  /**
   * Initialise the queue backend.
   * Must be called after RedisService.connect().
   */
  async init() {
    if (redisService.isRedis) {
      try {
        // Dynamic import — app works without bull installed
        const Bull = (await import("bull")).default;
        this._isBull = true;
        this._Bull = Bull;
        logger.info("✅ Job queue using Bull + Redis (distributed)");

        // Re-register any handlers that were registered before init
        for (const [jobType, handler] of this._handlers.entries()) {
          this._ensureBullQueue(jobType, handler);
        }
      } catch (err) {
        logger.warn("Bull not available — using in-process queue", {
          error: err.message,
        });
        this._backend = new InProcessQueue();
        // Re-register handlers
        for (const [jobType, handler] of this._handlers.entries()) {
          this._backend.registerHandler(jobType, handler);
        }
      }
    } else {
      this._backend = new InProcessQueue();
      logger.info("Job queue using in-process backend (single instance)");
      // Re-register handlers
      for (const [jobType, handler] of this._handlers.entries()) {
        this._backend.registerHandler(jobType, handler);
      }
    }
  }

  /** @private Create or retrieve a Bull queue for a job type */
  _ensureBullQueue(jobType, handler) {
    if (this._bullQueues.has(jobType)) return this._bullQueues.get(jobType);

    const redisUrl = process.env.REDIS_URL || process.env.REDIS_URI;
    const queue = new this._Bull(jobType, redisUrl, {
      defaultJobOptions: {
        attempts: 3,
        backoff: { type: "exponential", delay: 1000 },
        removeOnComplete: 100,
        removeOnFail: 50,
      },
    });

    queue.process(async (job) => {
      await handler(job.data);
    });

    queue.on("completed", (job) => {
      logger.debug("Job completed (Bull)", { jobId: job.id, type: jobType });
    });

    queue.on("failed", (job, err) => {
      logger.error("Job failed (Bull)", {
        jobId: job.id,
        type: jobType,
        error: err.message,
        attemptsMade: job.attemptsMade,
      });
    });

    this._bullQueues.set(jobType, queue);
    logger.info(`Bull queue registered: ${jobType}`);
    return queue;
  }

  /**
   * Register a handler for a job type.
   * Can be called before or after init().
   */
  registerHandler(jobType, handler) {
    this._handlers.set(jobType, handler);

    if (this._isBull) {
      this._ensureBullQueue(jobType, handler);
    } else if (this._backend) {
      this._backend.registerHandler(jobType, handler);
    }
    // If neither is ready yet, handlers are stored and applied during init()
  }

  /**
   * Enqueue a job for async processing.
   */
  async enqueue(jobType, payload, options = {}) {
    if (this._isBull) {
      const queue = this._bullQueues.get(jobType);
      if (!queue) {
        logger.warn(`No Bull queue for job type: ${jobType} — creating`);
        const handler = this._handlers.get(jobType);
        if (!handler) throw new Error(`No handler for job type: ${jobType}`);
        this._ensureBullQueue(jobType, handler);
      }
      const bullQueue = this._bullQueues.get(jobType);
      const job = await bullQueue.add(payload, {
        priority: options.priority === "high" ? 1 : options.priority === "low" ? 3 : 2,
        delay: options.delay || 0,
        attempts: options.maxRetries || 3,
      });
      logger.debug("Job enqueued (Bull)", { jobId: job.id, type: jobType });
      return job.id;
    }

    // Fallback
    if (this._backend) {
      return this._backend.enqueue(jobType, payload, options);
    }

    // Queue not initialised yet — fire-and-forget with timeout
    logger.warn("Job queue not ready, scheduling enqueue retry", { type: jobType });
    setTimeout(() => this.enqueue(jobType, payload, options), 500);
    return null;
  }

  /**
   * Get queue statistics.
   */
  async getStats() {
    if (this._isBull) {
      const stats = { backend: "bull+redis", queues: {} };
      for (const [name, queue] of this._bullQueues.entries()) {
        const counts = await queue.getJobCounts();
        stats.queues[name] = counts;
      }
      return stats;
    }
    return this._backend?.getStats() || { backend: "uninitialised" };
  }

  /**
   * Clear all pending jobs.
   */
  async clear() {
    if (this._isBull) {
      let total = 0;
      for (const queue of this._bullQueues.values()) {
        await queue.empty();
        total++;
      }
      return total;
    }
    return this._backend?.clear() || 0;
  }

  /**
   * Graceful shutdown.
   */
  async shutdown() {
    if (this._isBull) {
      for (const queue of this._bullQueues.values()) {
        await queue.close();
      }
      logger.info("Bull queues closed");
    } else if (this._backend) {
      await this._backend.shutdown();
    }
  }
}

// Singleton instance
const jobQueue = new JobQueue();

export default jobQueue;
