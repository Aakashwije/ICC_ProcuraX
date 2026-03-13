/**
 * Async Job Queue
 *
 * Lightweight in-process async job queue for background processing.
 * Handles notification delivery, scheduled tasks, and cleanup jobs.
 *
 * Design Decision: Using an in-process queue rather than Redis/Bull
 * for simplicity in this coursework scope. In production, this would
 * be replaced with a distributed queue (Bull + Redis, AWS SQS, etc.)
 * for horizontal scalability.
 */

import logger from "../logging/logger.js";

class JobQueue {
  constructor() {
    this._queue = [];
    this._processing = false;
    this._handlers = new Map();
    this._retryConfig = { maxRetries: 3, backoffMs: 1000 };
    this._stats = { enqueued: 0, processed: 0, failed: 0, retried: 0 };
  }

  /**
   * Register a handler for a job type
   * @param {string} jobType - Name of the job type
   * @param {Function} handler - Async function to process the job
   */
  registerHandler(jobType, handler) {
    this._handlers.set(jobType, handler);
    logger.info(`Job handler registered: ${jobType}`);
  }

  /**
   * Enqueue a job for async processing
   * @param {string} jobType - Type of job
   * @param {object} payload - Job data
   * @param {object} options - { priority, delay, maxRetries }
   */
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

    // If delay specified, schedule for later
    if (options.delay) {
      setTimeout(() => {
        this._queue.push(job);
        this._processQueue();
      }, options.delay);
    } else {
      this._queue.push(job);
    }

    this._stats.enqueued++;
    logger.debug("Job enqueued", { jobId: job.id, type: jobType });

    // Start processing if not already running
    if (!this._processing) {
      this._processQueue();
    }

    return job.id;
  }

  /**
   * Process jobs in the queue
   */
  async _processQueue() {
    if (this._processing || this._queue.length === 0) return;

    this._processing = true;

    while (this._queue.length > 0) {
      // Sort by priority (high first)
      this._queue.sort((a, b) => {
        const priorityOrder = { high: 0, normal: 1, low: 2 };
        return (priorityOrder[a.priority] || 1) - (priorityOrder[b.priority] || 1);
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
        logger.debug("Job completed", { jobId: job.id, type: job.type });
      } catch (err) {
        job.retryCount++;
        logger.error("Job failed", {
          jobId: job.id,
          type: job.type,
          error: err.message,
          retryCount: job.retryCount,
        });

        if (job.retryCount < job.maxRetries) {
          // Re-enqueue with exponential backoff
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
          logger.error("Job permanently failed after max retries", {
            jobId: job.id,
            type: job.type,
          });
        }
      }
    }

    this._processing = false;
  }

  /**
   * Get queue statistics
   */
  getStats() {
    return {
      ...this._stats,
      pending: this._queue.length,
      registeredHandlers: [...this._handlers.keys()],
    };
  }

  /**
   * Clear all pending jobs
   */
  clear() {
    const count = this._queue.length;
    this._queue = [];
    logger.info(`Job queue cleared, ${count} jobs removed`);
    return count;
  }
}

// Singleton instance
const jobQueue = new JobQueue();

export default jobQueue;
