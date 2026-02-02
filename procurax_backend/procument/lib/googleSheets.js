import { google } from "googleapis";
import path from "path";

// Absolute path to credentials.json
const KEYFILE = path.resolve(
  process.cwd(),
  "procument",
  "credentials.json"
);

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
