/**
 * Shared Google Auth helper.
 *
 * On Railway (production):
 *   Set the env var GOOGLE_SERVICE_ACCOUNT_JSON to the full JSON string
 *   of your service-account credentials.  No file needed on disk.
 *
 * Locally:
 *   Falls back to procurax_backend/credentials.json (git-ignored).
 */
import { google } from "googleapis";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SCOPES = ["https://www.googleapis.com/auth/spreadsheets.readonly"];

/**
 * Build a GoogleAuth instance.
 * Priority:
 *   1. GOOGLE_SERVICE_ACCOUNT_JSON env var  (Railway / production)
 *   2. GOOGLE_APPLICATION_CREDENTIALS env var (path to key file)
 *   3. credentials.json at the repo root     (local dev)
 */
function buildAuth() {
  // --- Option 1: env var contains the JSON string ---
  if (process.env.GOOGLE_SERVICE_ACCOUNT_JSON) {
    try {
      const creds = JSON.parse(process.env.GOOGLE_SERVICE_ACCOUNT_JSON);
      return new google.auth.GoogleAuth({
        credentials: creds,
        scopes: SCOPES,
      });
    } catch (err) {
      console.error(
        "❌ Failed to parse GOOGLE_SERVICE_ACCOUNT_JSON:",
        err.message
      );
    }
  }

  // --- Option 2: env var points to a key file ---
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    const absPath = path.isAbsolute(process.env.GOOGLE_APPLICATION_CREDENTIALS)
      ? process.env.GOOGLE_APPLICATION_CREDENTIALS
      : path.join(process.cwd(), process.env.GOOGLE_APPLICATION_CREDENTIALS);

    if (fs.existsSync(absPath)) {
      return new google.auth.GoogleAuth({
        keyFile: absPath,
        scopes: SCOPES,
      });
    }
    console.warn(
      `⚠️  GOOGLE_APPLICATION_CREDENTIALS points to ${absPath} which does not exist`
    );
  }

  // --- Option 3: local credentials.json (repo root) ---
  const localKeyFile = path.resolve(__dirname, "..", "credentials.json");
  if (fs.existsSync(localKeyFile)) {
    return new google.auth.GoogleAuth({
      keyFile: localKeyFile,
      scopes: SCOPES,
    });
  }

  console.error(
    "❌ No Google service-account credentials found. " +
      "Set GOOGLE_SERVICE_ACCOUNT_JSON env var or place credentials.json in procurax_backend/"
  );
  return null;
}

const auth = buildAuth();

/**
 * Pre-built Sheets client – import this directly:
 *   import { sheetsClient } from "../../config/googleAuth.js";
 */
export const sheetsClient = auth
  ? google.sheets({ version: "v4", auth })
  : null;

/**
 * Re-export extractSheetId / extractGid so existing imports still work.
 */
export function extractSheetId(url) {
  if (!url) return null;
  const match = url.match(/\/d\/([a-zA-Z0-9-_]+)/);
  return match ? match[1] : url;
}

export function extractGid(url) {
  if (!url) return null;
  const match = url.match(/[?&#]gid=(\d+)/);
  return match ? match[1] : null;
}

export { auth };
export default sheetsClient;
