/**
 * Environment Configuration Validation
 * 
 * Validates all required environment variables at startup.
 * Fails fast if critical configuration is missing.
 */

import logger from "../logging/logger.js";

const requiredVariables = [
  {
    name: "MONGODB_URI",
    aliases: ["MONGO_URI"],
    description: "MongoDB connection string",
    critical: true,
  },
  {
    name: "JWT_SECRET",
    description: "JWT signing secret",
    critical: true,
    minLength: 32,
  },
];

const optionalVariables = [
  {
    name: "PORT",
    default: "5002",
    description: "Server port",
  },
  {
    name: "NODE_ENV",
    default: "development",
    description: "Environment (development/production)",
    validValues: ["development", "production", "test"],
  },
  {
    name: "JWT_EXPIRE",
    default: "7d",
    description: "JWT expiration time",
  },
  {
    name: "SMTP_HOST",
    description: "SMTP server host for email",
  },
  {
    name: "SMTP_PORT",
    default: "587",
    description: "SMTP server port",
  },
  {
    name: "SMTP_USER",
    description: "SMTP username",
  },
  {
    name: "SMTP_PASS",
    description: "SMTP password",
  },
  {
    name: "GOOGLE_SHEET_ID",
    description: "Default Google Sheet ID for procurement",
  },
  {
    name: "CACHE_TTL_MS",
    default: "60000",
    description: "Cache TTL in milliseconds",
  },
  {
    name: "REDIS_URL",
    description: "Redis connection URL for caching",
  },
  {
    name: "REDIS_URI",
    description: "Redis connection URI (alias for REDIS_URL)",
  },
  {
    name: "DB_POOL_SIZE",
    default: "10",
    description: "MongoDB connection pool size",
  },
  {
    name: "DB_SLOW_QUERY_MS",
    default: "200",
    description: "Slow query threshold in milliseconds",
  },
  {
    name: "ALERT_WEBHOOK_URL",
    description: "Webhook URL for performance alerts (Slack/Teams)",
  },
];

/**
 * Get environment variable with fallback to aliases
 */
const getEnvValue = (varConfig) => {
  let value = process.env[varConfig.name];

  if (!value && varConfig.aliases) {
    for (const alias of varConfig.aliases) {
      value = process.env[alias];
      if (value) break;
    }
  }

  return value;
};

/**
 * Validate all environment variables
 */
export const validateEnvironment = () => {
  const errors = [];
  const warnings = [];

  logger.info("Validating environment configuration...");

  // Check required variables
  for (const varConfig of requiredVariables) {
    const value = getEnvValue(varConfig);

    if (!value) {
      if (varConfig.critical) {
        errors.push(`Missing required environment variable: ${varConfig.name} (${varConfig.description})`);
      } else {
        warnings.push(`Missing recommended variable: ${varConfig.name} (${varConfig.description})`);
      }
      continue;
    }

    // Check minimum length if specified
    if (varConfig.minLength && value.length < varConfig.minLength) {
      errors.push(
        `${varConfig.name} must be at least ${varConfig.minLength} characters (security requirement)`
      );
    }

    // Check valid values if specified
    if (varConfig.validValues && !varConfig.validValues.includes(value)) {
      warnings.push(
        `${varConfig.name}="${value}" is not a recognized value. Expected: ${varConfig.validValues.join(", ")}`
      );
    }
  }

  // Set defaults for optional variables
  for (const varConfig of optionalVariables) {
    const value = process.env[varConfig.name];

    if (!value && varConfig.default) {
      process.env[varConfig.name] = varConfig.default;
      logger.debug(`Set default: ${varConfig.name}=${varConfig.default}`);
    }

    // Check valid values if specified
    if (value && varConfig.validValues && !varConfig.validValues.includes(value)) {
      warnings.push(
        `${varConfig.name}="${value}" is not a recognized value. Expected: ${varConfig.validValues.join(", ")}`
      );
    }
  }

  // Log warnings
  warnings.forEach((warning) => {
    logger.warn(`ENV Warning: ${warning}`);
  });

  // Fail fast on errors
  if (errors.length > 0) {
    logger.error("Environment validation failed:");
    errors.forEach((error) => {
      logger.error(`  - ${error}`);
    });

    if (process.env.NODE_ENV === "production") {
      logger.error("Exiting due to missing critical configuration");
      process.exit(1);
    } else {
      logger.warn("Continuing in development mode despite missing configuration");
    }
  } else {
    logger.info("✅ Environment configuration validated successfully");
  }

  return { errors, warnings };
};

/**
 * Get configuration value with type conversion
 */
export const getConfig = (key, defaultValue = null) => {
  const value = process.env[key];

  if (value === undefined || value === null) {
    return defaultValue;
  }

  // Auto-convert boolean strings
  if (value === "true") return true;
  if (value === "false") return false;

  // Auto-convert numeric strings
  if (/^\d+$/.test(value)) return parseInt(value, 10);
  if (/^\d+\.\d+$/.test(value)) return parseFloat(value);

  return value;
};

export default {
  validateEnvironment,
  getConfig,
};
