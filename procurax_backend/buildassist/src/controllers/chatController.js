
import { google } from "googleapis";
import path from "path";
import { fileURLToPath } from "url";
import { parseProcurementSheet } from "../services/procurementSheetService.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let sheets;
try {
  const auth = new google.auth.GoogleAuth({
    keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS || 
             path.join(__dirname, '../../config/credentials.json'),
    scopes: ["https://www.googleapis.com/auth/spreadsheets.readonly"],
  });
  
  sheets = google.sheets({ version: "v4", auth });
} catch (error) {
  console.error("Failed to initialize Google Sheets:", error);
}

export const chatWithAI = async (req, res) => {
  try {
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({ 
        reply: "Please provide a message.",
        error: true 
      });
    }

    // Check if sheets is initialized
    if (!sheets || !process.env.GOOGLE_SHEET_ID) {
      return res.json({
        reply: "Google Sheets is not configured. Please check your environment variables.",
        error: true
      });
    }

    console.log("Fetching sheet data...");
    
    // Fetch data from Google Sheets - start from row 4
    const response = await sheets.spreadsheets.values.get({
      spreadsheetId: process.env.GOOGLE_SHEET_ID,
      range: "with equance!A4:R1000", // Skip the first 3 rows
    });

    console.log(`Sheet returned ${response.data.values?.length || 0} rows`);

    const rows = response.data.values;

    if (!rows || rows.length === 0) {
      return res.json({ 
        reply: "No procurement data found in the sheet." 
      });
    }

    // Parse the procurement data
    const procurementItems = parseProcurementSheet(rows);
    
    console.log(`Parsed ${procurementItems.length} items`);

    // If no items parsed, return error
    if (procurementItems.length === 0) {
      return res.json({
        reply: "Could not parse procurement data from the sheet. The sheet might have an unexpected format.",
        error: true
      });
    }

    // Handle different types of queries
    const query = message.toLowerCase();
    
    // Check for specific material queries
    if (query.includes('concrete')) {
      const concreteItems = procurementItems.filter(item => 
        item.material.toLowerCase().includes('concrete')
      );
      
      if (concreteItems.length > 0) {
        return res.json({
          reply: "Here's the concrete delivery information:",
          data: concreteItems[0],
          type: "procurement_data"
        });
      }
    }
    
    // Check for delivery queries
    if (query.includes('delivery') || query.includes('schedule')) {
      const upcomingItems = procurementItems
        .filter(item => item.revisedDelivery && item.revisedDelivery !== '')
        .slice(0, 5);
      
      if (upcomingItems.length > 0) {
        return res.json({
          reply: "Here are the upcoming deliveries:",
          data: upcomingItems,
          type: "delivery_schedule"
        });
      }
    }
    
    // Default response with sample data
    return res.json({
      reply: `Found ${procurementItems.length} items in the procurement schedule. Try asking about specific materials like "concrete" or "cables".`,
      data: procurementItems.slice(0, 3), // Show first 3 as sample
      type: "sample_data"
    });

  } catch (error) {
    console.error("===== FULL ERROR DETAILS =====");
    console.error("Error message:", error.message);
    console.error("Error code:", error.code);
    console.error("Error status:", error.status);
    console.error("Error details:", error.errors);
    console.error("==============================");
    
    return res.status(500).json({ 
      reply: "I'm having trouble accessing the procurement data right now. Please try again later.",
      error: true 
    });
  }
};


