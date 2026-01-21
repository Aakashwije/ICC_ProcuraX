console.log('Starting backend...');

require('dotenv').config();
const express = require('express');
const { getProcurementData } = require('./sheets');

const app = express();

app.get('/api/procurement', async (req, res) => {
  try {
    const sheetId = process.env.SHEET_ID;
    if (!sheetId) {
      console.error('SHEET_ID is not configured in environment');
      return res.status(500).json({ error: 'SHEET_ID not configured on server' });
    }
    // Allow a local mock mode to speed frontend development when Sheets access
    // isn't available. Set MOCK_SHEETS=1 in your .env to enable.
    if (process.env.MOCK_SHEETS === '1') {
      const mock = [
        {
          materialDescription: 'Cement Type A',
          tdsQty: '100',
          cmsRequiredDate: '2026-01-10',
          goodsAtLocationDate: null,
        },
        {
          materialDescription: 'Steel Rods',
          tdsQty: '50',
          cmsRequiredDate: '2026-01-08',
          goodsAtLocationDate: '2026-01-09',
        },
      ];

      return res.json(mock);
    }

    // Call sheet loader
    const data = await getProcurementData(sheetId);
    res.json(data);
  } catch (error) {
    // Log full error for server-side debugging, but return message to client
    console.error('API ERROR:', error && error.message ? error.message : error);
    res.status(500).json({ error: (error && error.message) ? error.message : 'Internal server error' });
  }
});

const http = require('http');

// health check
app.get('/health', (req, res) => res.json({ ok: true }));

const preferredPort = parseInt(process.env.PORT || '3000', 10);

function startServer(port, attempts = 0) {
  const server = http.createServer(app);

  server.listen(port, () => {
    console.log(`✅ Backend running on port ${port}`);
  });

  server.on('error', (err) => {
    if (err && err.code === 'EADDRINUSE' && attempts < 5) {
      console.warn(`Port ${port} in use, trying ${port + 1}...`);
      // small delay then retry
      setTimeout(() => startServer(port + 1, attempts + 1), 200);
      return;
    }
    console.error('Server failed to start:', err && err.message ? err.message : err);
    process.exit(1);
  });
}

startServer(preferredPort);
