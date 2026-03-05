
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
             path.join(__dirname, '../../config/google-credentials.json'),
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

    // Fetch data from Google Sheets
    const response = await sheets.spreadsheets.values.get({
      spreadsheetId: process.env.GOOGLE_SHEET_ID,
      range: "with equance!A1:R1000", // Use the actual sheet name from your Excel
    });

    const rows = response.data.values;

    if (!rows || rows.length === 0) {
      return res.json({ 
        reply: "No procurement data found in the sheet." 
      });
    }

    // Parse the procurement data
    const procurementItems = parseProcurementSheet(rows);
    
    // Handle different types of queries
    const query = message.toLowerCase();
    
    // Check for specific material queries
    if (query.includes('concrete') || query.includes('building a')) {
      const concreteItems = procurementItems.filter(item => 
        item.material.toLowerCase().includes('concrete') || 
        item.remarks.toLowerCase().includes('building a')
      );
      
      if (concreteItems.length > 0) {
        return res.json({
          reply: "Here's the concrete delivery information:",
          data: concreteItems[0], // Return the first matching item
          type: "procurement_data"
        });
      }
    }
    
    // Check for category queries
    const categories = ['electrical', 'plumbing', 'hvac', 'fire protection', 'civil'];
    for (const category of categories) {
      if (query.includes(category)) {
        const categoryItems = procurementItems.filter(item => 
          item.category.toLowerCase().includes(category)
        );
        
        if (categoryItems.length > 0) {
          return res.json({
            reply: `Here are the ${category} materials:`,
            data: categoryItems.slice(0, 5), // Return first 5 items
            type: "procurement_list"
          });
        }
      }
    }
    
    // Check for date/delivery queries
    if (query.includes('delivery') || query.includes('schedule') || query.includes('when')) {
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
    
    // General search across all items
    const keywords = query.split(' ');
    const matched = procurementItems.filter(item => {
      const searchText = `${item.material} ${item.category} ${item.remarks}`.toLowerCase();
      return keywords.some(keyword => keyword.length > 2 && searchText.includes(keyword));
    });
    
    if (matched.length > 0) {
      return res.json({
        reply: `Found ${matched.length} matching items:`,
        data: matched.slice(0, 3),
        type: "search_results"
      });
    }

    // Default response
    return res.json({
      reply: "I can help you with procurement information. Try asking about:\n• Specific materials (concrete, cables, etc.)\n• Categories (electrical, plumbing, HVAC)\n• Delivery schedules\n• Material status",
      type: "general"
    });

  } catch (error) {
    console.error("Chat controller error:", error);
    return res.status(500).json({ 
      reply: "I'm having trouble accessing the procurement data right now. Please try again later.",
      error: true 
    });
  }
};