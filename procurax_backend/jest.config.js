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
    "auth/**/*.js",
    "user/**/*.js",
    "settings/**/*.js",
    "procument/**/*.js",
    "communication/**/*.js",
    "media/**/*.js",
    "!**/node_modules/**",
    "!**/coverage/**",
    "!**/logs/**",
    "!buildassist/**/*",
  ],
  coverageDirectory: "coverage",
  coverageReporters: ["text", "text-summary", "lcov", "clover", "json-summary"],
  coverageThreshold: {
    global: {
      branches: 20,
      functions: 34,
      lines: 25,
      statements: 25,
    },
  },
  setupFilesAfterEnv: [],
  testTimeout: 10000,
  verbose: true,
};
