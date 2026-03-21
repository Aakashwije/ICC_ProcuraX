/**
 * Performance Monitor Service
 *
 * Real-time performance tracking with configurable alerting thresholds.
 * Monitors response times, memory usage, event loop lag, and database
 * latency. When a metric exceeds its threshold, an alert is emitted
 * to the logger (and optionally a webhook).
 *
 * Architecture:
 *   PerformanceMonitor
 *     ├── Periodic sampling (every N seconds)
 *     ├── Threshold checking & alert emission
 *     ├── Rolling window statistics (p50, p95, p99)
 *     └── Express endpoint for real-time dashboard data
 *
 * Alerting:
 *   Alerts are logged at WARN/ERROR level so they appear in log
 *   aggregation tools (Datadog, CloudWatch Logs, Grafana Loki).
 *   An optional ALERT_WEBHOOK_URL can POST JSON payloads for
 *   Slack / Teams / PagerDuty integration.
 */

import logger from "../logging/logger.js";

// ─── Default thresholds ─────────────────────────────────────────────
const DEFAULT_THRESHOLDS = {
  responseTimeP95Ms: 1000,       // 95th percentile response time
  responseTimeP99Ms: 3000,       // 99th percentile response time
  eventLoopLagMs: 100,           // Event loop delay
  heapUsedPercent: 85,           // Heap usage as % of total
  rssMB: 512,                    // Resident set size in MB
  dbQueryP95Ms: 500,             // 95th percentile DB query time
  errorRatePercent: 5,           // 5xx error rate over window
  activeConnections: 500,        // Max concurrent connections
};

class PerformanceMonitor {
  constructor() {
    this._thresholds = { ...DEFAULT_THRESHOLDS };
    this._alerts = [];                     // Recent alerts (ring buffer)
    this._maxAlerts = 100;
    this._responseTimes = [];              // Rolling window of recent response times
    this._dbQueryTimes = [];               // Rolling window of recent DB query times
    this._requestCounts = { total: 0, errors: 0 };
    this._snapshots = [];                  // Periodic system snapshots
    this._maxSnapshots = 360;              // ~30 min at 5s intervals
    this._samplingInterval = null;
    this._webhookUrl = process.env.ALERT_WEBHOOK_URL || null;
    this._started = false;

    logger.info("Performance monitor initialised", { thresholds: this._thresholds });
  }

  /**
   * Start periodic sampling and alerting.
   * @param {number} intervalMs — sampling interval (default 5 000ms)
   */
  start(intervalMs = 5_000) {
    if (this._started) return;
    this._started = true;

    this._samplingInterval = setInterval(() => this._sample(), intervalMs);
    if (this._samplingInterval.unref) this._samplingInterval.unref();

    logger.info("Performance monitor started", { intervalMs });
  }

  /**
   * Update alerting thresholds.
   */
  setThresholds(overrides) {
    Object.assign(this._thresholds, overrides);
    logger.info("Performance thresholds updated", { thresholds: this._thresholds });
  }

  // ─── Data ingestion ─────────────────────────────────────────────────

  /**
   * Record an HTTP response time (called from metrics middleware).
   */
  recordResponseTime(durationMs, statusCode) {
    this._responseTimes.push(durationMs);
    this._requestCounts.total++;
    if (statusCode >= 500) this._requestCounts.errors++;

    // Keep rolling window bounded
    if (this._responseTimes.length > 10_000) {
      this._responseTimes = this._responseTimes.slice(-5_000);
    }
  }

  /**
   * Record a database query time.
   */
  recordDbQueryTime(durationMs) {
    this._dbQueryTimes.push(durationMs);
    if (this._dbQueryTimes.length > 10_000) {
      this._dbQueryTimes = this._dbQueryTimes.slice(-5_000);
    }
  }

  // ─── Periodic sampling ──────────────────────────────────────────────

  _sample() {
    const mem = process.memoryUsage();
    const heapPercent = (mem.heapUsed / mem.heapTotal) * 100;
    const rssMB = mem.rss / 1024 / 1024;

    // Compute percentiles
    const rtP95 = this._percentile(this._responseTimes, 95);
    const rtP99 = this._percentile(this._responseTimes, 99);
    const rtP50 = this._percentile(this._responseTimes, 50);
    const dbP95 = this._percentile(this._dbQueryTimes, 95);

    // Compute event loop lag
    const lagStart = process.hrtime.bigint();
    setImmediate(() => {
      const lagMs = Number(process.hrtime.bigint() - lagStart) / 1_000_000;

      // Error rate
      const errorRate = this._requestCounts.total > 0
        ? (this._requestCounts.errors / this._requestCounts.total) * 100
        : 0;

      const snapshot = {
        timestamp: new Date().toISOString(),
        responseTime: { p50: rtP50, p95: rtP95, p99: rtP99 },
        memory: {
          heapUsedMB: Math.round(mem.heapUsed / 1024 / 1024 * 10) / 10,
          heapPercent: Math.round(heapPercent * 10) / 10,
          rssMB: Math.round(rssMB * 10) / 10,
        },
        eventLoopLagMs: Math.round(lagMs * 100) / 100,
        errorRate: Math.round(errorRate * 100) / 100,
        requestCount: this._requestCounts.total,
        dbQueryP95: dbP95,
      };

      this._snapshots.push(snapshot);
      if (this._snapshots.length > this._maxSnapshots) {
        this._snapshots = this._snapshots.slice(-Math.floor(this._maxSnapshots / 2));
      }

      // ── Check thresholds ──
      this._checkThreshold("responseTimeP95Ms", rtP95, "Response time P95");
      this._checkThreshold("responseTimeP99Ms", rtP99, "Response time P99");
      this._checkThreshold("eventLoopLagMs", lagMs, "Event loop lag");
      this._checkThreshold("heapUsedPercent", heapPercent, "Heap usage");
      this._checkThreshold("rssMB", rssMB, "RSS memory");
      this._checkThreshold("dbQueryP95Ms", dbP95, "DB query P95");
      this._checkThreshold("errorRatePercent", errorRate, "Error rate");
    });
  }

  // ─── Alerting ───────────────────────────────────────────────────────

  _checkThreshold(name, value, label) {
    const threshold = this._thresholds[name];
    if (value > threshold) {
      const alert = {
        level: value > threshold * 1.5 ? "critical" : "warning",
        metric: name,
        label,
        value: Math.round(value * 100) / 100,
        threshold,
        timestamp: new Date().toISOString(),
      };

      this._alerts.push(alert);
      if (this._alerts.length > this._maxAlerts) {
        this._alerts.shift();
      }

      const logFn = alert.level === "critical" ? logger.error : logger.warn;
      logFn.call(logger, `⚠️ Performance alert: ${label}`, {
        metric: name,
        value: alert.value,
        threshold,
        level: alert.level,
      });

      // Fire webhook if configured
      if (this._webhookUrl) {
        this._fireWebhook(alert).catch(() => {});
      }
    }
  }

  async _fireWebhook(alert) {
    try {
      const payload = JSON.stringify({
        text: `🚨 *${alert.level.toUpperCase()}* — ${alert.label}: ${alert.value} (threshold: ${alert.threshold})`,
        alert,
      });

      await fetch(this._webhookUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: payload,
        signal: AbortSignal.timeout(5_000),
      });
    } catch (err) {
      logger.debug("Alert webhook failed", { error: err.message });
    }
  }

  // ─── Percentile helper ──────────────────────────────────────────────

  _percentile(arr, pct) {
    if (arr.length === 0) return 0;
    const sorted = [...arr].sort((a, b) => a - b);
    const idx = Math.ceil((pct / 100) * sorted.length) - 1;
    return Math.round(sorted[Math.max(0, idx)] * 100) / 100;
  }

  // ─── Public API ─────────────────────────────────────────────────────

  /**
   * Get recent performance snapshots for dashboard display.
   */
  getSnapshots(limit = 60) {
    return this._snapshots.slice(-limit);
  }

  /**
   * Get recent alerts.
   */
  getAlerts(limit = 50) {
    return this._alerts.slice(-limit);
  }

  /**
   * Get current performance summary (for health endpoints).
   */
  getSummary() {
    const mem = process.memoryUsage();
    return {
      responseTime: {
        p50: this._percentile(this._responseTimes, 50),
        p95: this._percentile(this._responseTimes, 95),
        p99: this._percentile(this._responseTimes, 99),
        sampleSize: this._responseTimes.length,
      },
      memory: {
        heapUsedMB: Math.round(mem.heapUsed / 1024 / 1024 * 10) / 10,
        heapTotalMB: Math.round(mem.heapTotal / 1024 / 1024 * 10) / 10,
        rssMB: Math.round(mem.rss / 1024 / 1024 * 10) / 10,
        externalMB: Math.round(mem.external / 1024 / 1024 * 10) / 10,
      },
      database: {
        queryP95: this._percentile(this._dbQueryTimes, 95),
        queryP99: this._percentile(this._dbQueryTimes, 99),
        sampleSize: this._dbQueryTimes.length,
      },
      requests: { ...this._requestCounts },
      alerts: {
        recent: this._alerts.slice(-5),
        total: this._alerts.length,
      },
      thresholds: { ...this._thresholds },
      uptime: Math.round(process.uptime()),
    };
  }

  /**
   * Shutdown — clear intervals.
   */
  shutdown() {
    if (this._samplingInterval) {
      clearInterval(this._samplingInterval);
    }
    this._started = false;
    logger.info("Performance monitor stopped");
  }
}

// Singleton
const performanceMonitor = new PerformanceMonitor();

export default performanceMonitor;
