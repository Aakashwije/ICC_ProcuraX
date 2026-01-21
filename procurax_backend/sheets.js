const { google } = require('googleapis');

const auth = new google.auth.GoogleAuth({
  keyFile: 'credentials.json',
  scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'],
});

const sheets = google.sheets({ version: 'v4', auth });

async function getProcurementData(sheetId) {
  if (!sheetId) throw new Error('Missing required parameters: spreadsheetId');

  try {
    const response = await sheets.spreadsheets.values.get({
      spreadsheetId: sheetId,
      range: 'Sheet1!A2:D',
    });

    const values = response.data.values || [];

    return values.map(row => ({
      materialDescription: row[0] || '',
      tdsQty: row[1] != null ? String(row[1]) : '',
      cmsRequiredDate: row[2] || '',
      goodsAtLocationDate: row[3] || null,
    }));
  } catch (err) {
    // Rethrow with clearer message
    const message = (err && err.message) ? err.message : String(err);
    throw new Error(message);
  }
}

module.exports = { getProcurementData };
