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

// Increase timeout for async tests
jest.setTimeout(10000);

// Global beforeAll
beforeAll(async () => {
  // Setup code here
});

// Global afterAll
afterAll(async () => {
  // Cleanup code here
});
