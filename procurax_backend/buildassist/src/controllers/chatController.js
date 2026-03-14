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

const parseMeetingDetails = (message) => {
  const lowerMessage = message.toLowerCase();
  
  // Extract title - look for "titled" or "called" or just the first part
  let title = 'New Meeting';
  const titleMatch = message.match(/(?:titled|called|named)\s+['"]([^'"]+)['"]/i) || 
                    message.match(/meeting\s+(.+?)(?:\s+on|\s+at|\s+in|$)/i);
  if (titleMatch) {
    title = titleMatch[1].trim();
  }

  // Extract date - look for YYYY-MM-DD, MM/DD/YYYY, or day/month names (e.g., 23rd March)
  let dateStr = null;
  const dateMatch = message.match(/(\d{4}-\d{2}-\d{2}|\d{2}\/\d{2}\/\d{4})/);
  if (dateMatch) {
    dateStr = dateMatch[1];
  } else {
    // Detect patterns like "23rd March" or "March 23"
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

    const monthDayMatch = message.match(/(\d{1,2})(?:st|nd|rd|th)?\s+(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\s*(\d{4})?/i);
    if (monthDayMatch) {
      const day = parseInt(monthDayMatch[1], 10);
      const monthName = monthDayMatch[2].toLowerCase();
      const year = monthDayMatch[3] ? parseInt(monthDayMatch[3], 10) : new Date().getFullYear();
      const month = monthNames[monthName.toLowerCase()];
      if (month) {
        const paddedDay = String(day).padStart(2, '0');
        const paddedMonth = String(month).padStart(2, '0');
        dateStr = `${year}-${paddedMonth}-${paddedDay}`;
      }
    }
  }

  // Extract time - support 4pm, 4:30pm, 16:00, etc.
  let timeStr = null;
  // Only match time if it's followed by AM/PM or is in HH:MM format
  const timeMatch = message.match(/(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?|\d{1,2}\s*(?:AM|PM|am|pm))/i);
  if (timeMatch) {
    timeStr = timeMatch[1].trim();
    // Normalize times like '4pm' -> '4:00 PM'
    const simpleTimeMatch = timeStr.match(/^(\d{1,2})\s*(am|pm)$/i);
    if (simpleTimeMatch) {
      timeStr = `${simpleTimeMatch[1]}:00 ${simpleTimeMatch[2].toUpperCase()}`;
    }
  }

  // Extract location - look for "in" or "at" followed by location, but not if it contains a time
  let location = null;
  const locationMatch = message.match(/(?:in|at)\s+([^\d]{2,}.+?)(?:\s+on|\s+at|$)/i);
  if (locationMatch) {
    location = locationMatch[1].trim();
  }

  // Extract duration if mentioned (e.g., "for 1 hour")
  let durationMinutes = 60; // default 1 hour
  const durationMatch = message.match(/for\s+(\d+)\s*(hour|minute|min)/i);
  if (durationMatch) {
    const num = parseInt(durationMatch[1]);
    const unit = durationMatch[2].toLowerCase();
    if (unit.startsWith('hour')) {
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
        
        // Allow scheduling for all users (no authentication required).
        // If userId is missing, owner will be left undefined.


        const meetingDetails = parseMeetingDetails(message);
        console.log('Parsed meeting details:', meetingDetails);

        // Validate required fields
        if (!meetingDetails.dateStr || !meetingDetails.timeStr) {
          return res.json({
            reply: "Please provide both date and time for the meeting. Example: 'schedule a meeting titled \"Project Review\" on 2026-03-15 at 2:00 PM in Conference Room'",
          });
        }

        try {
          // Parse date and time
          const dateTimeStr = `${meetingDetails.dateStr} ${meetingDetails.timeStr}`;
          const startTime = new Date(dateTimeStr);
          
          if (isNaN(startTime.getTime())) {
            return res.json({
              reply: "Invalid date or time format. Please use formats like '2026-03-15 2:00 PM' or '03/15/2026 14:00'",
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
            // If user is not authenticated, create meetings under a generic internal owner.
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
            reply: "Failed to schedule the meeting. Please try again.",
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