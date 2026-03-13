/**
 * Jest Configuration for ProcuraX Backend
 * 
 * Uses native ESM support via --experimental-vm-modules.
 * Test files must import { jest, describe, it, expect, ... } from "@jest/globals"
 * OR rely on the globals injected by the injectGlobals setting.
 */

export default {
  testEnvironment: "node",
  transform: {},
  moduleFileExtensions: ["js", "mjs"],
  testMatch: ["**/__tests__/**/*.test.js", "**/?(*.)+(spec|test).js"],
  collectCoverageFrom: [
    "core/**/*.js",
    "tasks/**/*.js",
    "notes/**/*.js",
    "notifications/**/*.js",
    "meetings/**/*.js",
    "!**/node_modules/**",
    "!**/coverage/**",
    "!**/logs/**",
  ],
  coverageDirectory: "coverage",
  coverageReporters: ["text", "lcov", "clover"],
  setupFilesAfterEnv: [],
  testTimeout: 10000,
  verbose: true,
};
