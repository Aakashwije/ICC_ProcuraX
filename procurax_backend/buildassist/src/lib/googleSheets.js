/*
  Google Sheets helper for BuildAssist.
  Auth is handled by the shared config/googleAuth.js helper which
  reads credentials from env vars (Railway) or the local file (dev).
*/
import {
  sheetsClient as sheets,
  extractSheetId,
  extractGid,
} from "../../../config/googleAuth.js";

// Re-export so existing import sites keep working
export { extractSheetId, extractGid };

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
