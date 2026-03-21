/**
 * Metrics Service — Prometheus-Compatible Metrics Collection
 *
 * Collects application-level metrics and exposes them in Prometheus
 * text format at GET /metrics. Also provides an Express middleware
 * that automatically tracks HTTP request durations and status codes.
 *
 * Metrics collected:
 *   - http_requests_total          (counter)  — total requests by method/route/status
 *   - http_request_duration_ms     (histogram) — response time distribution
 *   - active_connections           (gauge)    — current in-flight requests
 *   - db_query_duration_ms         (histogram) — Mongoose operation latency
 *   - cache_hits_total / cache_misses_total (counters)
 *   - job_queue_processed_total / job_queue_failed_total (counters)
 *   - node_memory_usage_bytes      (gauge)    — heap / RSS
 *   - node_cpu_usage_percent       (gauge)    — process CPU
 *   - node_event_loop_lag_ms       (gauge)    — event loop delay
 *
 * Architecture:
 *   All metrics are stored in-memory in Maps / arrays. A /metrics
 *   endpoint serialises them into Prometheus exposition format so
 *   Grafana / Datadog / CloudWatch can scrape them.
 */

import logger from "../logging/logger.js";

// ─── Histogram buckets (ms) ─────────────────────────────────────────
const HTTP_BUCKETS = [5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000];
const DB_BUCKETS = [1, 5, 10, 25, 50, 100, 250, 500, 1000];

class MetricsService {
  constructor() {
    // Counters
    this._httpRequests = new Map();      // "method:route:status" → count
    this._cacheHits = 0;
    this._cacheMisses = 0;
    this._jobsProcessed = 0;
    this._jobsFailed = 0;

    // Histograms (store individual observations for bucket calculation)
    this._httpDurations = [];            // { route, method, duration }
    this._dbDurations = [];

    // Gauges
    this._activeConnections = 0;
    this._eventLoopLag = 0;

    // Start periodic collectors
    this._startPeriodicCollection();

    logger.info("Metrics service initialised");
  }

  // ─── HTTP metrics ───────────────────────────────────────────────────

  /**
   * Express middleware — records request count, duration, active connections.
   */
  httpMiddleware() {
    return (req, res, next) => {
      const start = process.hrtime.bigint();
      this._activeConnections++;

      const onFinish = () => {
        this._activeConnections--;
        const durationNs = Number(process.hrtime.bigint() - start);
        const durationMs = durationNs / 1_000_000;

        // Normalise route to avoid high-cardinality labels
        const route = this._normaliseRoute(req.route?.path || req.path);
        const method = req.method;
        const status = res.statusCode;

        // Increment counter
        const key = `${method}:${route}:${status}`;
        this._httpRequests.set(key, (this._httpRequests.get(key) || 0) + 1);

        // Record duration (keep last 10 000 samples to bound memory)
        this._httpDurations.push({ route, method, duration: durationMs });
        if (this._httpDurations.length > 10_000) {
          this._httpDurations = this._httpDurations.slice(-5_000);
        }

        res.removeListener("finish", onFinish);
      };

      res.on("finish", onFinish);
      next();
    };
  }

  // ─── Cache metrics ──────────────────────────────────────────────────

  recordCacheHit() { this._cacheHits++; }
  recordCacheMiss() { this._cacheMisses++; }

  // ─── Job queue metrics ──────────────────────────────────────────────

  recordJobProcessed() { this._jobsProcessed++; }
  recordJobFailed() { this._jobsFailed++; }

  // ─── Database metrics ───────────────────────────────────────────────

  recordDbQuery(operation, durationMs) {
    this._dbDurations.push({ operation, duration: durationMs });
    if (this._dbDurations.length > 10_000) {
      this._dbDurations = this._dbDurations.slice(-5_000);
    }
  }

  // ─── Periodic system metrics ────────────────────────────────────────

  _startPeriodicCollection() {
    // Measure event loop lag every 2 seconds
    this._lagInterval = setInterval(() => {
      const start = process.hrtime.bigint();
      setImmediate(() => {
        this._eventLoopLag = Number(process.hrtime.bigint() - start) / 1_000_000;
      });
    }, 2_000);

    // Prevent the interval from keeping the process alive
    if (this._lagInterval.unref) this._lagInterval.unref();
  }

  // ─── Route normalisation ────────────────────────────────────────────

  _normaliseRoute(path) {
    return path
      .replace(/\/[0-9a-fA-F]{24}/g, "/:id")    // MongoDB ObjectIds
      .replace(/\/\d+/g, "/:num")                 // numeric IDs
      .replace(/\/{2,}/g, "/")                     // double slashes
      || "/";
  }

  // ─── Histogram helpers ──────────────────────────────────────────────

  _computeHistogram(observations, buckets) {
    const result = {};
    for (const b of buckets) {
      result[`le_${b}`] = observations.filter((o) => o.duration <= b).length;
    }
    result["le_Inf"] = observations.length;
    result.count = observations.length;
    result.sum = observations.reduce((s, o) => s + o.duration, 0);
    return result;
  }

  // ─── Prometheus text format ─────────────────────────────────────────

  /**
   * Serialise all metrics to Prometheus exposition format.
   */
  toPrometheus() {
    const lines = [];
    const ts = Date.now();

    // ── http_requests_total ──
    lines.push("# HELP http_requests_total Total HTTP requests");
    lines.push("# TYPE http_requests_total counter");
    for (const [key, count] of this._httpRequests.entries()) {
      const [method, route, status] = key.split(":");
      lines.push(
        `http_requests_total{method="${method}",route="${route}",status="${status}"} ${count}`
      );
    }

    // ── http_request_duration_ms ──
    lines.push("# HELP http_request_duration_ms HTTP request duration histogram");
    lines.push("# TYPE http_request_duration_ms histogram");
    const httpHist = this._computeHistogram(this._httpDurations, HTTP_BUCKETS);
    for (const b of HTTP_BUCKETS) {
      lines.push(`http_request_duration_ms_bucket{le="${b}"} ${httpHist[`le_${b}`]}`);
    }
    lines.push(`http_request_duration_ms_bucket{le="+Inf"} ${httpHist["le_Inf"]}`);
    lines.push(`http_request_duration_ms_count ${httpHist.count}`);
    lines.push(`http_request_duration_ms_sum ${httpHist.sum.toFixed(2)}`);

    // ── active_connections ──
    lines.push("# HELP active_connections Current in-flight HTTP requests");
    lines.push("# TYPE active_connections gauge");
    lines.push(`active_connections ${this._activeConnections}`);

    // ── cache ──
    lines.push("# HELP cache_hits_total Total cache hits");
    lines.push("# TYPE cache_hits_total counter");
    lines.push(`cache_hits_total ${this._cacheHits}`);
    lines.push("# HELP cache_misses_total Total cache misses");
    lines.push("# TYPE cache_misses_total counter");
    lines.push(`cache_misses_total ${this._cacheMisses}`);

    // ── job queue ──
    lines.push("# HELP job_queue_processed_total Total jobs processed");
    lines.push("# TYPE job_queue_processed_total counter");
    lines.push(`job_queue_processed_total ${this._jobsProcessed}`);
    lines.push("# HELP job_queue_failed_total Total jobs failed");
    lines.push("# TYPE job_queue_failed_total counter");
    lines.push(`job_queue_failed_total ${this._jobsFailed}`);

    // ── db_query_duration_ms ──
    lines.push("# HELP db_query_duration_ms Database query duration histogram");
    lines.push("# TYPE db_query_duration_ms histogram");
    const dbHist = this._computeHistogram(this._dbDurations, DB_BUCKETS);
    for (const b of DB_BUCKETS) {
      lines.push(`db_query_duration_ms_bucket{le="${b}"} ${dbHist[`le_${b}`]}`);
    }
    lines.push(`db_query_duration_ms_bucket{le="+Inf"} ${dbHist["le_Inf"]}`);
    lines.push(`db_query_duration_ms_count ${dbHist.count}`);
    lines.push(`db_query_duration_ms_sum ${dbHist.sum.toFixed(2)}`);

    // ── Node.js runtime ──
    const mem = process.memoryUsage();
    lines.push("# HELP node_memory_heap_used_bytes Node.js heap used");
    lines.push("# TYPE node_memory_heap_used_bytes gauge");
    lines.push(`node_memory_heap_used_bytes ${mem.heapUsed}`);
    lines.push("# HELP node_memory_rss_bytes Node.js RSS");
    lines.push("# TYPE node_memory_rss_bytes gauge");
    lines.push(`node_memory_rss_bytes ${mem.rss}`);
    lines.push("# HELP node_memory_external_bytes Node.js external memory");
    lines.push("# TYPE node_memory_external_bytes gauge");
    lines.push(`node_memory_external_bytes ${mem.external}`);

    lines.push("# HELP node_event_loop_lag_ms Event loop lag");
    lines.push("# TYPE node_event_loop_lag_ms gauge");
    lines.push(`node_event_loop_lag_ms ${this._eventLoopLag.toFixed(3)}`);

    lines.push("# HELP process_uptime_seconds Process uptime");
    lines.push("# TYPE process_uptime_seconds gauge");
    lines.push(`process_uptime_seconds ${process.uptime().toFixed(0)}`);

    return lines.join("\n") + "\n";
  }

  /**
   * Return metrics as a JSON summary (for /health/metrics endpoint).
   */
  toJSON() {
    const mem = process.memoryUsage();
    const httpCount = [...this._httpRequests.values()].reduce((s, c) => s + c, 0);
    const avgDuration = this._httpDurations.length > 0
      ? this._httpDurations.reduce((s, o) => s + o.duration, 0) / this._httpDurations.length
      : 0;

    return {
      http: {
        totalRequests: httpCount,
        activeConnections: this._activeConnections,
        avgResponseTimeMs: Math.round(avgDuration * 100) / 100,
        requestsByRoute: Object.fromEntries(this._httpRequests),
      },
      cache: {
        hits: this._cacheHits,
        misses: this._cacheMisses,
        hitRate: this._cacheHits + this._cacheMisses > 0
          ? `${((this._cacheHits / (this._cacheHits + this._cacheMisses)) * 100).toFixed(1)}%`
          : "0%",
      },
      jobQueue: {
        processed: this._jobsProcessed,
        failed: this._jobsFailed,
      },
      database: {
        totalQueries: this._dbDurations.length,
        avgQueryTimeMs: this._dbDurations.length > 0
          ? Math.round(
              (this._dbDurations.reduce((s, o) => s + o.duration, 0) / this._dbDurations.length) * 100
            ) / 100
          : 0,
      },
      runtime: {
        uptimeSeconds: Math.round(process.uptime()),
        heapUsedMB: Math.round(mem.heapUsed / 1024 / 1024 * 10) / 10,
        rssMB: Math.round(mem.rss / 1024 / 1024 * 10) / 10,
        eventLoopLagMs: Math.round(this._eventLoopLag * 100) / 100,
      },
    };
  }

  /**
   * Shutdown — clear intervals.
   */
  shutdown() {
    clearInterval(this._lagInterval);
  }
}

// Singleton
const metrics = new MetricsService();

export default metrics;
