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
  Fetch raw procurement rows from Google Sheets.
  We convert each row into a clean object with named fields.
*/
export async function fetchProcurementData() {
  if (!process.env.GOOGLE_SHEET_ID) {
    throw new Error("Missing GOOGLE_SHEET_ID env var");
  }

  /*
    Read columns A to D starting from row 2 (A2:D).
    That matches the expected spreadsheet layout.
  */
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: process.env.GOOGLE_SHEET_ID,
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
