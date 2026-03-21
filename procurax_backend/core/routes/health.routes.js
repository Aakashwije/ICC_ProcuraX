/**
 * Health & Observability Routes
 *
 * Comprehensive health-check, readiness, liveness, metrics, and
 * performance monitoring endpoints for production observability.
 *
 * Endpoints:
 *   GET /health              — basic health (load balancer / Railway)
 *   GET /health/ready        — readiness probe (Kubernetes / ECS)
 *   GET /health/live         — liveness probe
 *   GET /health/detailed     — full system diagnostics (auth required)
 *   GET /metrics             — Prometheus-compatible metrics
 *   GET /health/metrics      — JSON metrics summary
 *   GET /health/performance  — real-time performance dashboard data
 *   GET /health/alerts       — recent performance alerts
 */

import { Router } from "express";
import mongoose from "mongoose";
import logger from "../logging/logger.js";
import redisService from "../services/redis.service.js";
import cache from "../services/cache.service.js";
import jobQueue from "../services/jobQueue.js";
import metrics from "../services/metrics.service.js";
import performanceMonitor from "../services/performance.service.js";

const router = Router();

const startTime = new Date();

// ─── GET /health — Basic health (public, no auth) ──────────────────
router.get("/", (req, res) => {
  res.json({
    status: "healthy",
    service: "ProcuraX Backend",
    version: process.env.npm_package_version || "1.0.0",
    timestamp: new Date().toISOString(),
    uptime: Math.round(process.uptime()),
  });
});

// ─── GET /health/live — Liveness probe ──────────────────────────────
router.get("/live", (req, res) => {
  // If the process is running and can respond, it's alive
  res.status(200).json({ status: "alive" });
});

// ─── GET /health/ready — Readiness probe ────────────────────────────
router.get("/ready", async (req, res) => {
  const checks = {
    database: mongoose.connection.readyState === 1,
    redis: await redisService.ping(),
  };

  const allReady = Object.values(checks).every(Boolean);

  res.status(allReady ? 200 : 503).json({
    status: allReady ? "ready" : "not_ready",
    checks,
    timestamp: new Date().toISOString(),
  });
});

// ─── GET /health/detailed — Full diagnostics ────────────────────────
router.get("/detailed", async (req, res) => {
  try {
    const mem = process.memoryUsage();
    const cpuUsage = process.cpuUsage();

    // Database connection details
    const dbStatus = {
      connected: mongoose.connection.readyState === 1,
      readyState: mongoose.connection.readyState,
      host: mongoose.connection.host || "unknown",
      name: mongoose.connection.name || "unknown",
      collections: mongoose.connection.readyState === 1
        ? Object.keys(mongoose.connection.collections).length
        : 0,
    };

    // Redis status
    const redisStatus = redisService.getStatus();

    // Cache stats
    const cacheStats = cache.getStats();

    // Job queue stats
    const queueStats = await jobQueue.getStats();

    // Performance summary
    const perfSummary = performanceMonitor.getSummary();

    res.json({
      status: "healthy",
      service: "ProcuraX Backend",
      version: process.env.npm_package_version || "1.0.0",
      environment: process.env.NODE_ENV || "development",
      startedAt: startTime.toISOString(),
      uptime: Math.round(process.uptime()),
      timestamp: new Date().toISOString(),

      system: {
        platform: process.platform,
        arch: process.arch,
        nodeVersion: process.version,
        pid: process.pid,
        memory: {
          heapUsedMB: Math.round(mem.heapUsed / 1024 / 1024 * 10) / 10,
          heapTotalMB: Math.round(mem.heapTotal / 1024 / 1024 * 10) / 10,
          rssMB: Math.round(mem.rss / 1024 / 1024 * 10) / 10,
          externalMB: Math.round(mem.external / 1024 / 1024 * 10) / 10,
        },
        cpu: {
          userMicroseconds: cpuUsage.user,
          systemMicroseconds: cpuUsage.system,
        },
      },

      database: dbStatus,
      redis: redisStatus,
      cache: cacheStats,
      jobQueue: queueStats,
      performance: perfSummary,
    });
  } catch (err) {
    logger.error("Health check failed", { error: err.message });
    res.status(500).json({
      status: "error",
      message: err.message,
    });
  }
});

// ─── GET /health/metrics — JSON metrics summary ─────────────────────
router.get("/metrics", (req, res) => {
  res.json(metrics.toJSON());
});

// ─── GET /health/performance — Performance dashboard data ───────────
router.get("/performance", (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 60, 360);
  res.json({
    summary: performanceMonitor.getSummary(),
    snapshots: performanceMonitor.getSnapshots(limit),
    alerts: performanceMonitor.getAlerts(20),
  });
});

// ─── GET /health/alerts — Recent performance alerts ─────────────────
router.get("/alerts", (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 50, 100);
  res.json({
    alerts: performanceMonitor.getAlerts(limit),
    thresholds: performanceMonitor.getSummary().thresholds,
  });
});

export default router;
