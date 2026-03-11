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
  console.log("Google Sheets initialized successfully");
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

    console.log("Received message:", message);
    console.log("Request body:", req.body);

    // Check if sheets is initialized
    if (!sheets || !process.env.GOOGLE_SHEET_ID) {
      console.log("Sheets not configured:", { 
        sheets: !!sheets, 
        sheetId: process.env.GOOGLE_SHEET_ID 
      });
      return res.json({
        reply: "Google Sheets is not configured. Please check your environment variables.",
        error: true
      });
    }

    console.log("Fetching sheet data with ID:", process.env.GOOGLE_SHEET_ID);
    
    let rows = null;
    
    try {
      // First, get the sheet metadata to find the correct sheet name
      console.log("Getting sheet metadata...");
      const metadata = await sheets.spreadsheets.get({
        spreadsheetId: process.env.GOOGLE_SHEET_ID
      });

      // Get the first sheet name
      const firstSheetName = metadata.data.sheets[0].properties.title;
      console.log(`Using sheet: "${firstSheetName}"`);

      // Now fetch data from that sheet
      console.log("Fetching data from sheet...");
      const response = await sheets.spreadsheets.values.get({
        spreadsheetId: process.env.GOOGLE_SHEET_ID,
        range: `${firstSheetName}!A6:R1000`, // Start from row 6
      });
      
      console.log("Sheet API call successful!");
      console.log(`Sheet returned ${response.data.values?.length || 0} rows`);
      rows = response.data.values;
      
    } catch (apiError) {
      console.error("===== GOOGLE SHEETS API ERROR =====");
      console.error("Error message:", apiError.message);
      console.error("Error code:", apiError.code);
      console.error("Error status:", apiError.status);
      if (apiError.response) {
        console.error("Response data:", apiError.response.data);
      }
      console.error("===================================");
      
      // Return a helpful error message
      return res.status(500).json({ 
        reply: "Cannot connect to Google Sheets. This might be due to network/firewall restrictions. Please check:\n1. Your internet connection\n2. Corporate firewall/VPN settings\n3. Google Sheets API access",
        error: true,
        details: apiError.message
      });
    }

    if (!rows || rows.length === 0) {
      return res.json({ 
        reply: "No procurement data found in the sheet." 
      });
    }

    // Parse the procurement data
    const procurementItems = parseProcurementSheet(rows);
    
    console.log(`Parsed ${procurementItems.length} procurement items`);
    if (procurementItems.length > 0) {
      console.log("First item sample:", JSON.stringify(procurementItems[0], null, 2));
    }

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
        item.material && item.material.toLowerCase().includes('concrete')
      );
      
      if (concreteItems.length > 0) {
        // Return all concrete items
        return res.json({
          reply: `Found ${concreteItems.length} concrete-related items:`,
          data: concreteItems.length === 1 ? concreteItems[0] : concreteItems,
          type: "procurement_data"
        });
      }
    }
    
    // Check for delivery queries
    if (query.includes('delivery') || query.includes('schedule')) {
      const upcomingItems = procurementItems
        .filter(item => item.revisedDelivery && item.revisedDelivery !== '')
        .slice(0, 10);
      
      if (upcomingItems.length > 0) {
        return res.json({
          reply: `Here are ${upcomingItems.length} upcoming deliveries:`,
          data: upcomingItems.length === 1 ? upcomingItems[0] : upcomingItems,
          type: "procurement_data"
        });
      }
    }
    
    // Check for category queries
    const categories = ['electrical', 'plumbing', 'hvac', 'civil', 'fire', 'elevator', 'generator'];
    for (const category of categories) {
      if (query.includes(category)) {
        const categoryItems = procurementItems.filter(item => 
          item.category && item.category.toLowerCase().includes(category)
        );
        
        if (categoryItems.length > 0) {
          return res.json({
            reply: `Found ${categoryItems.length} items in ${category} category:`,
            data: categoryItems.slice(0, 10),
            type: "procurement_data"
          });
        }
      }
    }
    
    // Check for status queries
    if (query.includes('pending')) {
      const pendingItems = procurementItems.filter(item => 
        item.status && item.status.toLowerCase().includes('pending')
      );
      
      if (pendingItems.length > 0) {
        return res.json({
          reply: `Found ${pendingItems.length} items with pending status:`,
          data: pendingItems.slice(0, 10),
          type: "procurement_data"
        });
      }
    }
    
    if (query.includes('drawing')) {
      const drawingPendingItems = procurementItems.filter(item => 
        item.status && item.status.toLowerCase().includes('drawing pending')
      );
      
      if (drawingPendingItems.length > 0) {
        return res.json({
          reply: `Found ${drawingPendingItems.length} items with drawing pending:`,
          data: drawingPendingItems.slice(0, 10),
          type: "procurement_data"
        });
      }
    }
    
    // Search by material name
    const searchResults = procurementItems.filter(item => 
      item.material && item.material.toLowerCase().includes(query)
    );
    
    if (searchResults.length > 0) {
      return res.json({
        reply: `Found ${searchResults.length} items matching "${message}":`,
        data: searchResults.slice(0, 10),
        type: "procurement_data"
      });
    }
    
    // Default response with summary
    const categories_summary = [...new Set(procurementItems.map(item => item.category).filter(c => c))];
    return res.json({
      reply: `Found ${procurementItems.length} items in the procurement schedule.\n\nAvailable categories:\n${categories_summary.slice(0, 10).join(', ')}\n\nTry asking about:\n• Concrete\n• Deliveries\n• Pending items\n• Specific materials`,
      data: procurementItems.slice(0, 5),
      type: "procurement_data"
    });

  } catch (error) {
    console.error("===== FULL ERROR DETAILS =====");
    console.error("Error message:", error.message);
    console.error("Error code:", error.code);
    console.error("Error status:", error.status);
    if (error.response) {
      console.error("Response data:", error.response.data);
    }
    console.error("Stack:", error.stack);
    console.error("==============================");
    
    return res.status(500).json({ 
      reply: "I'm having trouble accessing the procurement data right now. Please try again later.",
      error: true 
    });
  }
};