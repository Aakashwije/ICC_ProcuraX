// Google Sheets client helper used by procurement services.
// Loads credentials, configures auth, and provides a typed data fetch API.
import { google } from "googleapis";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Absolute path to credentials.json (located at procurax_backend/credentials.json)
const KEYFILE = path.resolve(__dirname, "..", "..", "credentials.json");

// Create auth using keyFile (MOST RELIABLE)
const auth = new google.auth.GoogleAuth({
  keyFile: KEYFILE,
  scopes: ["https://www.googleapis.com/auth/spreadsheets.readonly"],
});

// Create Sheets client
const sheets = google.sheets({
  version: "v4",
  auth,
});

// Fetch raw procurement rows from Google Sheets.
export async function fetchProcurementData() {
  if (!process.env.GOOGLE_SHEET_ID) {
    throw new Error("Missing GOOGLE_SHEET_ID env var");
  }

  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: process.env.GOOGLE_SHEET_ID,
    range: "A2:D",
  });

  return (res.data.values || []).map((row) => ({
    materialDescription: row[0] ?? "",
    tdsQty: row[1] ?? "",
    cmsRequiredDate: row[2] ?? "",
    goodsAtLocationDate: row[3] ?? "",
  }));
}
