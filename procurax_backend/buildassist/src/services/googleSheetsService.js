import { google } from "googleapis";
import path from "path";

const auth = new google.auth.GoogleAuth({
  keyFile: path.join("src/config/google-credentials.json"),
  scopes: ["https://www.googleapis.com/auth/spreadsheets.readonly"],
});

export const getSheetData = async () => {
  try {
    const client = await auth.getClient();

    const sheets = google.sheets({ version: "v4", auth: client });

    const response = await sheets.spreadsheets.values.get({
      spreadsheetId: "1ZBZTsw6RekdlOcMwiTKTT74V_5gvCNGkijNUgwaPoNQ",
      range: "Sheet1!A1:G100",
    });

    return response.data.values;
  } catch (error) {
    console.error("Error fetching sheet data:", error);
  }
};