import { google } from "googleapis";
import path from "path";
import { fileURLToPath } from "url";
import mongoose from "mongoose";
import { parseProcurementSheet } from "../services/procurementSheetService.js";
import {
  fetchUserMeetings,
  fetchUserNotes,
  fetchUserTasks,
  fetchUpcomingMeetings,
  fetchPendingTasks,
  searchNotes,
  searchTasks,
  searchMeetings,
  getDashboardSummary
} from "../services/dataFetchService.js";
import Meeting from "../../../meetings/models/Meeting.js";

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

const enrichProcurementItems = async (items, userId) => {
  return await Promise.all(items.map(async (item) => {
    const materialName = item.material || '';
    const relatedMeetings = await searchMeetings(userId, materialName);
    const relatedTasks = await searchTasks(userId, materialName);
    const relatedNotes = await searchNotes(userId, materialName);
    return { ...item, relatedMeetings, relatedTasks, relatedNotes };
  }));
};

/**
 * Parse relative date keywords (tomorrow, next monday, etc.)
 */
const parseRelativeDate = (message) => {
  const lowerMessage = message.toLowerCase();
  const today = new Date();
  
  // Tomorrow
  if (lowerMessage.includes('tomorrow')) {
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return formatDateStr(tomorrow);
  }
  
  // Today
  if (lowerMessage.includes('today')) {
    return formatDateStr(today);
  }
  
  // Next week keywords
  const dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  for (const day of dayNames) {
    if (lowerMessage.includes(`next ${day}`) || lowerMessage.includes(`upcoming ${day}`)) {
      const targetDayIndex = dayNames.indexOf(day);
      const nextDate = new Date(today);
      const currentDayIndex = today.getDay();
      let daysAhead = targetDayIndex - currentDayIndex;
      if (daysAhead <= 0) daysAhead += 7;
      nextDate.setDate(nextDate.getDate() + daysAhead);
      return formatDateStr(nextDate);
    }
  }
  
  return null;
};

const formatDateStr = (date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

const parseMeetingDetails = (message) => {
  const lowerMessage = message.toLowerCase();
  
  // Extract title - careful not to include keywords like "titled"
  let title = 'New Meeting';
  
  // First try: quoted text (highest priority)
  let titleMatch = message.match(/['"]([^'"]+)['"]/);
  if (titleMatch && titleMatch[1]) {
    title = titleMatch[1].trim();
  } else {
    // Second try: "titled <title>" or "called <title>" patterns (without quotes)
    titleMatch = message.match(/(?:titled|called|named)\s+([^\s][^on]+?)(?:\s+(?:on|at|tomorrow|today|next|for)|\s*$)/i);
    if (titleMatch && titleMatch[1]) {
      let extractedTitle = titleMatch[1].trim();
      // Remove any trailing date/time keywords
      extractedTitle = extractedTitle.replace(/\s+(?:on|at|tomorrow|today|next|for).*/i, '');
      if (extractedTitle.length > 0 && extractedTitle.length < 100 && !['titled', 'called', 'named'].includes(extractedTitle.toLowerCase())) {
        title = extractedTitle;
      }
    }
  }

  // Extract date - try multiple approaches
  let dateStr = null;
  
  // First try relative dates (tomorrow, next monday, etc.)
  dateStr = parseRelativeDate(message);
  
  // Then try standard formats
  if (!dateStr) {
    const dateMatch = message.match(/(\d{4}-\d{2}-\d{2}|\d{2}\/\d{2}\/\d{4})/);
    if (dateMatch) {
      dateStr = dateMatch[1];
    }
  }
  
  // Try day/month patterns (flexible)
  if (!dateStr) {
    const monthNames = {
      jan: 1, january: 1,
      feb: 2, february: 2,
      mar: 3, march: 3,
      apr: 4, april: 4,
      may: 5,
      jun: 6, june: 6,
      jul: 7, july: 7,
      aug: 8, august: 8,
      sep: 9, sept: 9, september: 9,
      oct: 10, october: 10,
      nov: 11, november: 11,
      dec: 12, december: 12,
    };

    // More flexible month-day matching
    const monthDayMatch = message.match(/(\d{1,2})(?:st|nd|rd|th)?\s+(Jan|January|Feb|February|Mar|March|Apr|April|May|Jun|June|Jul|July|Aug|August|Sep|Sept|September|Oct|October|Nov|November|Dec|December)\s*(\d{4})?/i);
    if (monthDayMatch) {
      const day = parseInt(monthDayMatch[1], 10);
      const monthName = monthDayMatch[2].toLowerCase();
      const year = monthDayMatch[3] ? parseInt(monthDayMatch[3], 10) : new Date().getFullYear();
      const month = monthNames[monthName];
      if (month) {
        const paddedDay = String(day).padStart(2, '0');
        const paddedMonth = String(month).padStart(2, '0');
        dateStr = `${year}-${paddedMonth}-${paddedDay}`;
      }
    }
  }

  // Extract time - more flexible matching
  let timeStr = null;
  // Match patterns like: 4pm, 4:30pm, 16:00, 4 pm, 4:30 pm, 2:00 PM, etc.
  const timeMatch = message.match(/(\d{1,2})\s*:?\s*(\d{2})?\s*(am|pm|AM|PM)?/);
  if (timeMatch) {
    const hour = timeMatch[1];
    const minute = timeMatch[2] || '00';
    const meridiem = timeMatch[3] ? timeMatch[3].toUpperCase() : 'AM';
    timeStr = `${hour}:${minute} ${meridiem}`;
  }

  // Extract location - more flexible patterns
  let location = null;
  const locationMatch = message.match(/(?:in|at|room)\s+([^.\n]+?)(?:\s+(?:on|at|time|tomorrow|today|next)|\.|\s*$)/i);
  if (locationMatch && locationMatch[1]) {
    location = locationMatch[1].trim().replace(/\s+on.*/i, '');
  }

  // Extract duration if mentioned
  let durationMinutes = 60; // default 1 hour
  const durationMatch = message.match(/(?:for|duration)\s+(\d+)\s*(hour|hr|minute|min)/i);
  if (durationMatch) {
    const num = parseInt(durationMatch[1]);
    const unit = durationMatch[2].toLowerCase();
    if (unit.startsWith('hour') || unit === 'hr') {
      durationMinutes = num * 60;
    } else {
      durationMinutes = num;
    }
  }

  return { title, dateStr, timeStr, location, durationMinutes };
};

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

    // ===== SCHEDULE MEETING =====
    if (tokens.includes('schedule') || tokens.includes('create') || tokens.includes('new')) {
      if (tokens.includes('meeting') || tokens.includes('meet')) {
        console.log('🔍 Schedule meeting branch triggered');
        
        const meetingDetails = parseMeetingDetails(message);
        console.log('Parsed meeting details:', meetingDetails);

        // Use smart defaults if date or time is missing
        let dateStr = meetingDetails.dateStr;
        let timeStr = meetingDetails.timeStr;

        // Default to tomorrow if no date specified
        if (!dateStr) {
          const tomorrow = new Date();
          tomorrow.setDate(tomorrow.getDate() + 1);
          dateStr = formatDateStr(tomorrow);
        }

        // Require time - ask user if not specified
        if (!timeStr) {
          return res.json({
            reply: `I can schedule a meeting on ${dateStr}. What time would you like? Please provide a time like '2pm', '2:30pm', '14:00', or '2:00 PM'`,
          });
        }

        try {
          // Parse date and time
          const dateTimeStr = `${dateStr} ${timeStr}`;
          const startTime = new Date(dateTimeStr);
          
          if (isNaN(startTime.getTime())) {
            return res.json({
              reply: "I had trouble parsing the meeting details. Please specify the date and time more clearly. Example: 'schedule meeting \"Project Review\" on tomorrow at 2pm' or 'schedule meeting \"Team Sync\" on 2026-03-20 at 3:00 PM'",
            });
          }

          // Validate that the meeting is not in the past
          const now = new Date();
          if (startTime < now) {
            return res.json({
              reply: `The meeting time (${startTime.toLocaleString()}) is in the past. Please pick a future date or time. Would you like to schedule it for tomorrow instead?`,
            });
          }

          const endTime = new Date(startTime.getTime() + meetingDetails.durationMinutes * 60000);

          // Create the meeting
          const newMeeting = new Meeting({
            title: meetingDetails.title,
            description: `Scheduled via BuildAssist: ${message}`,
            location: meetingDetails.location,
            startTime,
            endTime,
            priority: 'medium',
            owner: userId || mongoose.Types.ObjectId(),
          });

          await newMeeting.save();

          return res.json({
            reply: `✅ Meeting scheduled successfully!\n\n📅 **${meetingDetails.title}**\n🕐 ${startTime.toLocaleString()} - ${endTime.toLocaleString()}\n📍 ${meetingDetails.location || 'No location specified'}`,
            type: "meeting_scheduled"
          });

        } catch (error) {
          console.error('Error scheduling meeting:', error);
          return res.status(500).json({
            reply: "Failed to schedule the meeting. Please try again or contact support.",
            error: true
          });
        }
      }
    }

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

    const lowerMessage = message.toLowerCase();

if (
  lowerMessage.includes('procurement') ||
  lowerMessage.includes('material') ||
  lowerMessage.includes('materials') ||
  lowerMessage.includes('show procurement status') ||
  lowerMessage.includes('material status')
) {
  const enrichedItems = await enrichProcurementItems(
    procurementItems.slice(0, 10),
    userId
  );

  console.log('✅ Returning procurement_data');
  console.log('Total procurement items:', procurementItems.length);
  console.log('Sending first items:', enrichedItems.length);

  return res.json({
    reply: `Found ${procurementItems.length} procurement items. Showing first 10.`,
    data: enrichedItems,
    type: "procurement_data"
  });
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
        const enrichedItems = await enrichProcurementItems(items.slice(0, 10), userId);
        return res.json({
          reply: `Found ${items.length} concrete items:`,
          data: enrichedItems,
          type: "procurement_data"
        });
      }
    }

    if (tokens.includes('delivery')) {
      const items = procurementItems.filter(item => item.revisedDelivery).slice(0, 10);
      console.log('   delivery items count', items.length);
      if (items.length > 0) {
        const enrichedItems = await enrichProcurementItems(items, userId);
        return res.json({
          reply: `Found ${items.length} deliveries:`,
          data: enrichedItems,
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
          const enrichedItems = await enrichProcurementItems(items.slice(0, 10), userId);
          return res.json({
            reply: `Found ${items.length} ${cat} items:`,
            data: enrichedItems,
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
      const enrichedItems = await enrichProcurementItems(searchResults.slice(0, 10), userId);
      return res.json({
        reply: `Found ${searchResults.length} items:`,
        data: enrichedItems,
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