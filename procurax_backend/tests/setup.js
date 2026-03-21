/**
 * Jest Test Setup
 * 
 * Runs before all test suites.
 */

import { jest, beforeAll, afterAll } from "@jest/globals";

// Set test environment variables
process.env.NODE_ENV = "test";
process.env.JWT_SECRET = "test-secret-key-for-jwt-signing-minimum-32-chars";
process.env.MONGODB_URI = "mongodb://127.0.0.1:27017/procurax_test";

// Don't set REDIS_URL in test environment to use in-memory fallback
delete process.env.REDIS_URL;

// Increase timeout for async tests
jest.setTimeout(15000);

// Global beforeAll
beforeAll(async () => {
  // Setup code here - initialize services
});

// Global afterAll
afterAll(async () => {
  // Cleanup code here
});
