/*
  Google Sheets helper for procurement.
  This file connects to Google Sheets and returns clean rows
  so the rest of the backend does not worry about auth details.
*/
import { google } from "googleapis";
import path from "path";
import { fileURLToPath } from "url";

/*
  In ESM (module) files, we build __filename and __dirname manually.
  This lets us resolve the credentials.json path reliably.
*/
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/*
  Absolute path to credentials.json (stored in procurax_backend/credentials.json).
  This key file is used by GoogleAuth to access the Sheets API.
*/
const KEYFILE = path.resolve(__dirname, "..", "..", "credentials.json");

/*
  Create GoogleAuth using the key file and read-only Sheets scope.
  We only need read access for procurement data.
*/
const auth = new google.auth.GoogleAuth({
  keyFile: KEYFILE,
  scopes: ["https://www.googleapis.com/auth/spreadsheets.readonly"],
});

/*
  Create a Sheets client that will execute API calls for us.
*/
const sheets = google.sheets({
  version: "v4",
  auth,
});

/*
  Extract the Sheet ID from a full Google Sheets URL.
  Example: https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit -> 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms
*/
export function extractSheetId(url) {
  if (!url) return null;
  const match = url.match(/\/d\/([a-zA-Z0-9-_]+)/);
  return match ? match[1] : url; // fallback to the raw string if it's already an ID
}

/*
  Extract the gid (sheet tab ID) from a Google Sheets URL.
  Example: ...edit?gid=257866353 -> 257866353
*/
export function extractGid(url) {
  if (!url) return null;
  const match = url.match(/[?&#]gid=(\d+)/);
  return match ? match[1] : null;
}

/*
  Fetch raw procurement rows from Google Sheets.
  We convert each row into a clean object with named fields.
  Accepts an optional sheetUrl. If not provided, falls back to GOOGLE_SHEET_ID env var.
  Supports specific sheet tabs via gid parameter.
*/
export async function fetchProcurementData(sheetUrl) {
  const extractedId = extractSheetId(sheetUrl);
  const spreadsheetId = extractedId || process.env.GOOGLE_SHEET_ID;
  const gid = extractGid(sheetUrl);

  if (!spreadsheetId) {
    throw new Error("Missing Google Sheet ID (No URL provided and no GOOGLE_SHEET_ID env var)");
  }

  /*
    If a gid is provided, we need to find the sheet name for that gid.
    Otherwise, default to the first sheet.
  */
  let sheetName = "";
  if (gid) {
    try {
      const spreadsheetMeta = await sheets.spreadsheets.get({
        spreadsheetId,
        fields: "sheets.properties",
      });
      const sheet = spreadsheetMeta.data.sheets?.find(
        (s) => String(s.properties?.sheetId) === gid
      );
      if (sheet?.properties?.title) {
        sheetName = `'${sheet.properties.title}'!`;
      }
    } catch (err) {
      console.warn("Could not resolve sheet name from gid, using default sheet:", err.message);
    }
  }

  /*
    Read columns A to P starting from row 2.
    That matches the expected spreadsheet layout.
  */
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId,
    range: `${sheetName}A2:P`,
  });

  /*
    Map rows to objects so the service layer has
    predictable keys instead of array indexes.
  */
 return (res.data.values || []).map((row) => ({
  materialList: row[1] ?? "",          // B
  responsibility: row[3] ?? "",        // D
  openingLC: row[9] ?? "",             // J
  etd: row[10] ?? "",                  // K
  eta: row[11] ?? "",                  // L
  boiApproval: row[12] ?? "",          // M
  revisedDeliveryToSite: row[14] ?? "",// O
  requiredDateCMS: row[15] ?? ""       // P
}));
}
