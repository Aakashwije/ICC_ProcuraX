/**
 * Database Optimization Module
 *
 * Provides optimised MongoDB connection configuration with:
 *   - Connection pooling (configurable pool size)
 *   - Replica set support for read scaling and high availability
 *   - Mongoose query profiling middleware (logs slow queries)
 *   - Index management and verification utilities
 *   - Query helper for lean reads and projection
 *
 * Architecture:
 *   ┌──────────────────────────────────────────────────┐
 *   │               Application                        │
 *   │  ┌────────────────────────────────────────────┐  │
 *   │  │  Mongoose (ODM)                            │  │
 *   │  │  ┌──────────────────────────────────────┐  │  │
 *   │  │  │  Connection Pool (10–50 connections)  │  │  │
 *   │  │  └──────────────┬───────────────────────┘  │  │
 *   │  └─────────────────┼──────────────────────────┘  │
 *   └───────────────────┼──────────────────────────────┘
 *                       ▼
 *        ┌──────────────────────────────┐
 *        │     MongoDB Atlas / RS       │
 *        │  ┌────────┐ ┌────────────┐   │
 *        │  │Primary │ │Secondaries │   │
 *        │  │ (R/W)  │ │  (reads)   │   │
 *        │  └────────┘ └────────────┘   │
 *        └──────────────────────────────┘
 */

import mongoose from "mongoose";
import logger from "../logging/logger.js";
import metrics from "../services/metrics.service.js";

// ─── Connection Options ─────────────────────────────────────────────

/**
 * Build optimised Mongoose connection options.
 * Reads from environment variables with sensible defaults.
 */
export const getConnectionOptions = () => {
  const poolSize = parseInt(process.env.DB_POOL_SIZE) || 10;
  const env = process.env.NODE_ENV || "development";

  const options = {
    // ── Connection Pool ──
    maxPoolSize: poolSize,
    minPoolSize: Math.max(2, Math.floor(poolSize / 4)),

    // ── Timeouts ──
    serverSelectionTimeoutMS: 10_000,   // 10s to find a server
    socketTimeoutMS: 45_000,            // 45s for operations
    connectTimeoutMS: 10_000,           // 10s to establish connection
    heartbeatFrequencyMS: 10_000,       // 10s heartbeat

    // ── Write Concern ──
    w: "majority",                       // Wait for majority replication
    journal: true,                       // Wait for journal write
    retryWrites: true,                   // Auto-retry write operations
    retryReads: true,                    // Auto-retry read operations

    // ── Read Preference (for replica sets) ──
    readPreference: env === "production" ? "secondaryPreferred" : "primary",

    // ── Monitoring ──
    maxIdleTimeMS: 30_000,              // Close idle connections after 30s
    compressors: ["zstd", "snappy"],    // Wire compression
  };

  logger.info("MongoDB connection options configured", {
    poolSize: `${options.minPoolSize}–${options.maxPoolSize}`,
    readPreference: options.readPreference,
    writeConcern: options.w,
    compression: options.compressors.join(", "),
  });

  return options;
};

// ─── Query Profiling Plugin ─────────────────────────────────────────

/**
 * Mongoose plugin that profiles every query and logs slow ones.
 * Also feeds duration data to the metrics service.
 *
 * Usage: mongoose.plugin(queryProfilerPlugin);
 */
export const queryProfilerPlugin = (schema) => {
  const SLOW_THRESHOLD_MS = parseInt(process.env.DB_SLOW_QUERY_MS) || 200;

  // Profile find / findOne / findOneAndUpdate / etc.
  const hookOps = [
    "find",
    "findOne",
    "findOneAndUpdate",
    "findOneAndDelete",
    "countDocuments",
    "estimatedDocumentCount",
    "aggregate",
    "updateOne",
    "updateMany",
    "deleteOne",
    "deleteMany",
    "insertMany",
  ];

  for (const op of hookOps) {
    schema.pre(op, function () {
      this._queryStartTime = process.hrtime.bigint();
    });

    schema.post(op, function () {
      if (!this._queryStartTime) return;

      const durationNs = Number(process.hrtime.bigint() - this._queryStartTime);
      const durationMs = durationNs / 1_000_000;

      // Feed metrics
      metrics.recordDbQuery(op, durationMs);

      // Log slow queries
      if (durationMs > SLOW_THRESHOLD_MS) {
        const queryInfo = {
          operation: op,
          collection: this.model?.collection?.name || this._collection?.name || "unknown",
          durationMs: Math.round(durationMs * 100) / 100,
          filter: this.getFilter ? JSON.stringify(this.getFilter()).substring(0, 200) : "N/A",
        };

        logger.warn("⚠️ Slow query detected", queryInfo);
      }
    });
  }
};

// ─── Index Manager ──────────────────────────────────────────────────

/**
 * Verify that all schema indexes exist in the database.
 * Logs missing indexes as warnings.
 */
export const verifyIndexes = async () => {
  const models = mongoose.modelNames();
  const results = { total: 0, verified: 0, missing: 0 };

  for (const name of models) {
    const model = mongoose.model(name);
    try {
      const indexes = await model.collection.indexes();
      const schemaIndexes = model.schema.indexes();

      results.total += schemaIndexes.length;

      for (const [fields] of schemaIndexes) {
        const fieldKeys = Object.keys(fields);
        const exists = indexes.some((idx) =>
          fieldKeys.every((key) => key in idx.key)
        );

        if (exists) {
          results.verified++;
        } else {
          results.missing++;
          logger.warn("Missing index", {
            model: name,
            fields: fieldKeys.join(", "),
          });
        }
      }
    } catch (err) {
      logger.error("Index verification failed for model", {
        model: name,
        error: err.message,
      });
    }
  }

  logger.info("Index verification complete", results);
  return results;
};

/**
 * Ensure all indexes are created (idempotent).
 */
export const ensureIndexes = async () => {
  const models = mongoose.modelNames();

  for (const name of models) {
    try {
      await mongoose.model(name).ensureIndexes();
      logger.debug(`Indexes ensured for: ${name}`);
    } catch (err) {
      logger.error(`Index creation failed for: ${name}`, { error: err.message });
    }
  }

  logger.info("All model indexes ensured");
};

// ─── Query Helpers ──────────────────────────────────────────────────

/**
 * Mongoose plugin that adds common query helpers for optimisation.
 *
 * Usage in service layer:
 *   Task.find(filter).lean().select("title status").paginate(1, 20);
 */
export const queryHelperPlugin = (schema) => {
  /**
   * Paginate results with skip/limit.
   * @param {number} page — 1-based page number
   * @param {number} limit — items per page
   */
  schema.query.paginate = function (page = 1, limit = 20) {
    const skip = (Math.max(1, page) - 1) * limit;
    return this.skip(skip).limit(Math.min(limit, 100));
  };

  /**
   * Select only commonly needed fields (reduces transfer size).
   * Each model can override this with a custom projection.
   */
  schema.query.brief = function () {
    // Default brief projection — override per model
    return this.select("-__v");
  };

  /**
   * Force lean (POJO) results for read-only queries.
   * ~5× faster than returning Mongoose documents.
   */
  schema.query.asPlain = function () {
    return this.lean({ virtuals: true });
  };
};

// ─── Connection Event Handlers ──────────────────────────────────────

/**
 * Attach event handlers to monitor the Mongoose connection lifecycle.
 */
export const attachConnectionHandlers = (connection = mongoose.connection) => {
  connection.on("connected", () => {
    logger.info("✅ MongoDB connected", {
      host: connection.host,
      name: connection.name,
      readyState: connection.readyState,
    });
  });

  connection.on("disconnected", () => {
    logger.warn("MongoDB disconnected");
  });

  connection.on("reconnected", () => {
    logger.info("MongoDB reconnected");
  });

  connection.on("error", (err) => {
    logger.error("MongoDB error", { error: err.message });
  });

  connection.on("close", () => {
    logger.info("MongoDB connection closed");
  });

  // Monitor connection pool
  if (connection.getClient) {
    try {
      const client = connection.getClient();
      client.on("connectionPoolCreated", (event) => {
        logger.debug("Connection pool created", {
          maxPoolSize: event.options?.maxPoolSize,
        });
      });

      client.on("connectionCheckedOut", () => {
        logger.debug("Connection checked out from pool");
      });

      client.on("connectionPoolCleared", () => {
        logger.warn("Connection pool cleared");
      });
    } catch {
      // Client might not be available yet
    }
  }
};

// ─── Graceful Shutdown ──────────────────────────────────────────────

/**
 * Close the Mongoose connection gracefully.
 */
export const closeConnection = async () => {
  try {
    await mongoose.connection.close();
    logger.info("MongoDB connection closed gracefully");
  } catch (err) {
    logger.error("Error closing MongoDB connection", { error: err.message });
  }
};

export default {
  getConnectionOptions,
  queryProfilerPlugin,
  queryHelperPlugin,
  verifyIndexes,
  ensureIndexes,
  attachConnectionHandlers,
  closeConnection,
};
