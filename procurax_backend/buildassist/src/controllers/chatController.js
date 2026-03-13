import { google } from "googleapis";
import path from "path";
import { fileURLToPath } from "url";
import { parseProcurementSheet } from "../services/procurementSheetService.js";
import {
  fetchUserMeetings,
  fetchUserNotes,
  fetchUserTasks,
  fetchUpcomingMeetings,
  fetchPendingTasks,
  searchNotes,
  searchTasks,
  getDashboardSummary
} from "../services/dataFetchService.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let sheets;
try {
  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS 
    ? path.join(process.cwd(), process.env.GOOGLE_APPLICATION_CREDENTIALS)
    : path.join(__dirname, '../../credentials.json');
  
  const auth = new google.auth.GoogleAuth({
    keyFile: credentialsPath,
    scopes: ["https://www.googleapis.com/auth/spreadsheets.readonly"],
  });
  
  sheets = google.sheets({ version: "v4", auth });
} catch (error) {
  console.error("❌ Failed to initialize Google Sheets:", error.message);
}

export const chatWithAI = async (req, res) => {
  try {
    const { message } = req.body;
    const userId = req.user?.id; // Optional - may be null

    if (!message) {
      return res.status(400).json({ 
        reply: "Please provide a message.",
        error: true 
      });
    }

    const rawQuery = message.toLowerCase();
    console.log('BuildAssist query received:', rawQuery);

    // remove punctuation
    const sanitized = rawQuery.replace(/[^a-z0-9\s]/g, '').trim();
    // drop common filler words
    const stopWords = ['show','please','me','give','list','items','details','about','the','a','an','of','for','you'];
    const tokens = sanitized
      .split(/\s+/)
      .filter(w => w.length > 0 && !stopWords.includes(w));
    console.log('Parsed tokens:', tokens);
    const query = tokens.join(' ');

    // ===== MEETINGS =====
    if (tokens.includes('meeting') || tokens.includes('meetings') || tokens.includes('schedule') || tokens.includes('upcoming')) {
      console.log('🔍 Meeting branch triggered');
      const upcomingMeetings = await fetchUserMeetings(null);
      console.log('   → meetings count', upcomingMeetings.length);
      return res.json({
        reply: upcomingMeetings.length > 0 
          ? `You have ${upcomingMeetings.length} upcoming meetings:`
          : "You don't have any upcoming meetings.",
        data: upcomingMeetings,
        type: "meetings_data"
      });
    }

    // ===== TASKS =====
    if (tokens.includes('task') || tokens.includes('tasks') || tokens.includes('todo') || tokens.includes('pending') || tokens.includes('stuck') || tokens.includes('blocked')) {
      console.log('🔍 Task branch triggered');
      const pendingTasks = await fetchUserTasks(null);
      console.log('   → pendingTasks count', pendingTasks.length);
      return res.json({
        reply: pendingTasks.length > 0 
          ? `You have ${pendingTasks.length} pending tasks:`
          : "No pending tasks. Great!",
        data: pendingTasks,
        type: "tasks_data"
      });
    }

    // ===== NOTES =====
    if (tokens.includes('note') || tokens.includes('notes') || tokens.includes('search')) {
      console.log('🔍 Notes branch triggered');
      const keywords = tokens.filter(w => !['note','notes','search','find'].includes(w));
      const searchKeyword = keywords[0] || '';
      const noteResults = await fetchUserNotes(null);
      const filtered = searchKeyword 
        ? noteResults.filter(note => note.title.toLowerCase().includes(searchKeyword) || note.content?.toLowerCase().includes(searchKeyword))
        : noteResults;
      console.log('   → noteResults count', filtered.length);
      return res.json({
        reply: filtered.length > 0 
          ? `Found ${filtered.length} notes${searchKeyword ? ` matching "${searchKeyword}"` : ''}:`
          : "No notes found.",
        data: filtered.slice(0, 10),
        type: "notes_data"
      });
    }

    // ===== DASHBOARD =====
    if (tokens.includes('summary') || tokens.includes('dashboard')) {
      console.log('🔍 Dashboard branch triggered');
      const summary = await getDashboardSummary(null);
      console.log('   → dashboard summary', summary);
      return res.json({
        reply: `Dashboard Summary:\n• Meetings: ${summary?.summary?.totalMeetings || 0}\n• Notes: ${summary?.summary?.totalNotes || 0}\n• Pending: ${summary?.summary?.pendingTasks || 0}`,
        data: summary,
        type: "dashboard_data"
      });
    }

    // ===== PROCUREMENT =====
    if (!sheets || !process.env.GOOGLE_SHEET_ID) {
      return res.json({ reply: "Procurement data unavailable", error: true });
    }

    let rows = null;
    try {
      const metadata = await sheets.spreadsheets.get({ spreadsheetId: process.env.GOOGLE_SHEET_ID });
      const sheetName = metadata.data.sheets[0].properties.title;
      const sheetResponse = await sheets.spreadsheets.values.get({
        spreadsheetId: process.env.GOOGLE_SHEET_ID,
        range: `${sheetName}!A2:R1000`,
      });
      rows = sheetResponse.data.values;
    } catch (apiError) {
      return res.status(500).json({ reply: "Cannot access Google Sheets", error: true });
    }

    if (!rows || rows.length === 0) {
      return res.json({ reply: "No procurement data found" });
    }

    const procurementItems = parseProcurementSheet(rows);
    if (procurementItems.length === 0) {
      return res.json({ reply: "Could not parse procurement data", error: true });
    }

    // Procurement queries
    console.log('🔍 Procurement tokens:', tokens);
    console.log('   Total items parsed:', procurementItems.length);
    if (procurementItems.length > 0) {
      console.log('   First item sample:', JSON.stringify(procurementItems[0], null, 2));
    }

    if (tokens.includes('concrete')) {
      const items = procurementItems.filter(item => item.material?.toLowerCase().includes('concrete'));
      console.log('   concrete items count', items.length);
      if (items.length > 0) {
        return res.json({
          reply: `Found ${items.length} concrete items:`,
          data: items.slice(0, 10),
          type: "procurement_data"
        });
      }
    }

    if (tokens.includes('delivery')) {
      const items = procurementItems.filter(item => item.revisedDelivery).slice(0, 10);
      console.log('   delivery items count', items.length);
      if (items.length > 0) {
        return res.json({
          reply: `Found ${items.length} deliveries:`,
          data: items,
          type: "procurement_data"
        });
      }
    }

    const categories = [
      'electrical', 'low voltage', 'protection', 'plumbing', 'hvac', 'civil', 
      'fire', 'elevator', 'concrete', 'glass', 'steel', 'generator', 'elv',
      'lightning', 'detection', 'system'
    ];
    for (const cat of categories) {
      if (tokens.includes(cat)) {
        const items = procurementItems.filter(item => 
          item.category?.toLowerCase().includes(cat) ||
          item.parentCategory?.toLowerCase().includes(cat) ||
          item.material?.toLowerCase().includes(cat)
        );
        console.log(`   category/material "${cat}" matched, count`, items.length);
        if (items.length > 0) {
          return res.json({
            reply: `Found ${items.length} ${cat} items:`,
            data: items.slice(0, 10),
            type: "procurement_data"
          });
        }
      }
    }

    // generic search using any remaining token(s) – include both material and category
    const searchResults = procurementItems.filter(item =>
      tokens.some(term =>
        item.material?.toLowerCase().includes(term) ||
        item.category?.toLowerCase().includes(term)
      )
    );
    console.log('   generic search results count', searchResults.length);
    if (searchResults.length > 0) {
      return res.json({
        reply: `Found ${searchResults.length} items:`,
        data: searchResults.slice(0, 10),
        type: "procurement_data"
      });
    }

    return res.json({
      reply: `I can help with:\n• Meetings\n• Tasks\n• Notes\n• Procurement items\nWhat would you like?`,
      type: "help"
    });

  } catch (error) {
    console.error("Error:", error.message);
    return res.status(500).json({ reply: "Error processing request", error: true });
  }
};