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
  Fetch raw procurement rows from Google Sheets.
  We convert each row into a clean object with named fields.
  Accepts an optional sheetUrl. If not provided, falls back to GOOGLE_SHEET_ID env var.
*/
export async function fetchProcurementData(sheetUrl) {
  const extractedId = extractSheetId(sheetUrl);
  const spreadsheetId = extractedId || process.env.GOOGLE_SHEET_ID;

  if (!spreadsheetId) {
    throw new Error("Missing Google Sheet ID (No URL provided and no GOOGLE_SHEET_ID env var)");
  }

  /*
    Read columns A to D starting from row 2 (A2:D).
    That matches the expected spreadsheet layout.
  */
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId,
    range: "A2:D",
  });

  /*
    Map rows to objects so the service layer has
    predictable keys instead of array indexes.
  */
  return (res.data.values || []).map((row) => ({
    materialDescription: row[0] ?? "",
    tdsQty: row[1] ?? "",
    cmsRequiredDate: row[2] ?? "",
    goodsAtLocationDate: row[3] ?? "",
  }));
}
