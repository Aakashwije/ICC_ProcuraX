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
import Note from "../../../notes/notes.model.js";
import Task from "../../../tasks/tasks.model.js";
import NoteService from "../../../core/services/note.service.js";
import TaskService from "../../../core/services/task.service.js";
import NotificationService from "../../../notifications/notification.service.js";

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
  console.log("✅ Google Sheets initialized successfully");
  if (process.env.GOOGLE_SHEET_ID) {
    console.log(`✅ Google Sheet ID configured: ${process.env.GOOGLE_SHEET_ID.slice(0, 8)}...`);
  } else {
    console.warn("⚠️ GOOGLE_SHEET_ID not set in environment variables — procurement features will be unavailable");
  }
} catch (error) {
  console.error("❌ Failed to initialize Google Sheets:", error.message);
}

/**
 * Levenshtein distance between two strings (edit distance).
 * Used for fuzzy matching user input against known keywords.
 */
const levenshtein = (a, b) => {
  const m = a.length, n = b.length;
  const dp = Array.from({ length: m + 1 }, () => Array(n + 1).fill(0));
  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      dp[i][j] = a[i - 1] === b[j - 1]
        ? dp[i - 1][j - 1]
        : 1 + Math.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
    }
  }
  return dp[m][n];
};

/**
 * Find the closest match for a token from a list of known words.
 * Returns { match, distance } or null if no close match found.
 * Threshold: max 2 edits for words >=5 chars, max 1 for shorter words.
 */
const fuzzyMatch = (token, knownWords) => {
  let bestMatch = null;
  let bestDist = Infinity;
  for (const word of knownWords) {
    const dist = levenshtein(token, word.toLowerCase());
    if (dist < bestDist) {
      bestDist = dist;
      bestMatch = word;
    }
  }
  const maxDist = token.length >= 5 ? 2 : 1;
  if (bestDist > 0 && bestDist <= maxDist) {
    return { match: bestMatch.toLowerCase(), original: token, distance: bestDist };
  }
  return null;
};

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
export const parseRelativeDate = (message) => {
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

export const formatDateStr = (date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

export const parseMeetingDetails = (message) => {
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

/**
 * Parse note creation details (title and content)
 */
export const parseNoteDetails = (message) => {
  const lowerMessage = message.toLowerCase();
  
  let title = 'Untitled Note';
  let content = message;
  let tag = 'Issue';
  
  // Extract title from quoted text (highest priority)
  let titleMatch = message.match(/['"]([^'"]+)['"]/);
  if (titleMatch && titleMatch[1]) {
    title = titleMatch[1].trim();
    // Content becomes the rest of the message minus the title
    content = message.replace(/['"][^'"]+['"]\s*/i, '').trim();
  } else {
    // Try to extract title from "titled" or "named" patterns
    let extractedTitle = message.match(/(?:titled|named|about)\s+([^\n.]+?)(?:\s+(?:content|saying|note:|says:)|\n|$)/i);
    if (extractedTitle && extractedTitle[1]) {
      title = extractedTitle[1].trim();
      content = message.replace(new RegExp(`(?:titled|named|about)\s+${extractedTitle[1].replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\s*`, 'i'), '').trim();
    }
  }
  
  // Extract tag if mentioned (e.g., "bug", "feature", "issue", "idea", "urgent")
  const tagMatch = message.match(/(?:tag:|tagged as|as\s+)\s*([\w-]+)/i);
  if (tagMatch && tagMatch[1]) {
    const potentialTag = tagMatch[1].trim();
    if (['bug', 'feature', 'issue', 'idea', 'urgent', 'important', 'reminder', 'todo'].includes(potentialTag.toLowerCase())) {
      tag = potentialTag.charAt(0).toUpperCase() + potentialTag.slice(1);
    }
  }
  
  // Clean content by stripping command syntax
  const cleanupPatterns = /\b(create|add|write|new|a|make)\s+(a\s+)?note\b/gi;
  content = content.replace(cleanupPatterns, '').replace(/^\s*[-:,]\s*/, '').trim();
  
  // Ensure we have meaningful content
  if (!content || content.length < 5) {
    content = title; // Use title as content if nothing meaningful remains
  }
  
  return { title, content, tag };
};

/**
 * Parse task details (title, description, priority, due date)
 */
export const parseTaskDetails = (message) => {
  const lowerMessage = message.toLowerCase();
  
  let title = 'New Task';
  let description = message;
  let priority = 'medium';
  let dueDate = null;
  let status = 'todo';
  
  // Extract title from quoted text
  let titleMatch = message.match(/['"]([^'"]+)['"]/);
  if (titleMatch && titleMatch[1]) {
    title = titleMatch[1].trim();
    description = message.replace(/['"][^'"]+['"]\s*/i, '').trim();
  } else {
    // Try patterns like "task <title>" or "add <title>"
    let extractedTitle = message.match(/(?:task|add|create)\s+([^\n.]+?)(?:\s+(?:priority|due|by|with|urgent|high|low|medium|critical)|\n|$)/i);
    if (extractedTitle && extractedTitle[1].length < 100) {
      title = extractedTitle[1].trim();
      description = message.replace(new RegExp(`(?:task|add|create)\s+${extractedTitle[1].replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\s*`, 'i'), '').trim();
    }
  }
  
  // Extract priority
  if (lowerMessage.includes('critical') || lowerMessage.includes('asap') || lowerMessage.includes('urgent')) {
    priority = 'critical';
  } else if (lowerMessage.includes('high') || lowerMessage.includes('important')) {
    priority = 'high';
  } else if (lowerMessage.includes('low') || lowerMessage.includes('eventually')) {
    priority = 'low';
  }
  
  // Extract due date
  dueDate = parseRelativeDate(message) || null;
  
  // Clean description by stripping command syntax
  const cleanupPatterns = /\b(create|add|assign|new|a|make)\s+(a\s+)?task\b/gi;
  description = description.replace(cleanupPatterns, '').replace(/^\s*[-:,]\s*/, '').trim();
  
  // Ensure we have meaningful title
  if (!title || title === 'New Task' || title.length < 3) {
    title = description.split(/\n|\.|,/)[0].substring(0, 100).trim() || 'New Task';
  }
  
  return { title, description, priority, dueDate, status };
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
    console.log('BuildAssist query received:', rawQuery, '| userId:', userId || 'NOT AUTHENTICATED');

    // ===== GREETINGS & CONVERSATIONAL =====
    const greetings = ['hi', 'hello', 'hey', 'good morning', 'good afternoon', 'good evening', 'howdy', 'whats up'];
    if (greetings.some(g => rawQuery.includes(g)) && rawQuery.length < 30) {
      return res.json({
        reply: `Hello! I'm your BuildAssist AI assistant. Here's what I can help you with:\n\n📅 **Meetings** — View, search, or schedule meetings\n✅ **Tasks** — View, create, or track tasks\n📝 **Notes** — View, create, or search notes\n🏗️ **Materials** — Check procurement status & schedules\n📊 **Dashboard** — Get a project summary\n\nJust type what you need, or tap a quick action below!`,
        type: "help",
        suggestions: ["Show my meetings", "Create a task", "Material status", "Dashboard summary"]
      });
    }

    const thankYouWords = ['thank', 'thanks', 'thx', 'appreciate', 'great job', 'awesome', 'perfect'];
    if (thankYouWords.some(w => rawQuery.includes(w)) && rawQuery.length < 40) {
      return res.json({
        reply: "You're welcome! Is there anything else I can help you with?",
        type: "ai",
        suggestions: ["Show my tasks", "Create a note", "Material status"]
      });
    }

    const helpWords = ['help', 'what can you do', 'how to', 'guide', 'tutorial', 'instructions'];
    if (helpWords.some(w => rawQuery.includes(w)) && !rawQuery.includes('task') && !rawQuery.includes('note') && !rawQuery.includes('meeting')) {
      return res.json({
        reply: `Here's everything I can do:\n\n📅 **Meetings**\n• "Show my meetings" — view upcoming meetings\n• "Schedule meeting titled Review at 2pm tomorrow" — create a meeting\n\n✅ **Tasks**\n• "Show my tasks" — view pending tasks\n• "Add task \"Review plans\" high priority due tomorrow"\n\n📝 **Notes**\n• "Show my notes" — view all notes\n• "Create note \"Site Report\" tag: important"\n\n🏗️ **Materials**\n• "Show materials" — view all procurement items\n• "Concrete status" — search specific materials\n\n📊 "Dashboard summary" — quick project overview`,
        type: "help",
        suggestions: ["Show my meetings", "Show my tasks", "Show materials", "Dashboard summary"]
      });
    }

    // remove punctuation
    const sanitized = rawQuery.replace(/[^a-z0-9\s]/g, '').trim();
    // drop common filler words
    const stopWords = ['show','please','me','my','give','list','items','details','about','the','a','an','of','for','you','all','get','fetch','view','our'];
    const tokens = sanitized
      .split(/\s+/)
      .filter(w => w.length > 0 && !stopWords.includes(w));
    console.log('Parsed tokens:', tokens);

    // Auto-correct misspelled intent keywords (meeting, task, note, etc.)
    const intentKeywords = [
      'meeting', 'meetings', 'schedule', 'upcoming', 'create', 'new', 'add',
      'task', 'tasks', 'todo', 'pending', 'stuck', 'blocked', 'assign',
      'note', 'notes', 'search', 'write',
      'summary', 'dashboard',
      'procurement', 'material', 'materials', 'delivery',
      'concrete', 'electrical', 'plumbing', 'hvac', 'civil', 'fire',
      'elevator', 'glass', 'steel', 'generator', 'lightning', 'detection',
      'system', 'protection'
    ];
    const correctedIntentTokens = tokens.map(token => {
      if (intentKeywords.includes(token)) return token;
      const fuzzy = fuzzyMatch(token, intentKeywords);
      if (fuzzy) {
        console.log(`   🔧 Intent auto-corrected "${token}" → "${fuzzy.match}"`);
        return fuzzy.match;
      }
      return token;
    });
    // Use corrected tokens for intent detection, keep original for content extraction
    const intentTokens = correctedIntentTokens;
    console.log('Intent tokens (after correction):', intentTokens);

    const query = tokens.join(' ');

    // ===== SCHEDULE MEETING =====
    if (intentTokens.includes('schedule') || intentTokens.includes('create') || intentTokens.includes('new')) {
      if (intentTokens.includes('meeting') || intentTokens.includes('meet')) {
        console.log('🔍 Schedule meeting branch triggered');
        
        // Require authentication for meeting scheduling
        if (!userId) {
          return res.status(401).json({
            reply: "Please log in to schedule meetings. Your session may have expired — try logging in again.",
            error: true,
            suggestions: ["Show materials", "Material status"]
          });
        }
        
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
            owner: userId,
          });

          await newMeeting.save();

          return res.json({
            reply: `✅ Meeting scheduled successfully!\n\n📅 **${meetingDetails.title}**\n🕐 ${startTime.toLocaleString()} - ${endTime.toLocaleString()}\n📍 ${meetingDetails.location || 'No location specified'}`,
            type: "meeting_scheduled",
            suggestions: ["Show my meetings", "Create a task", "Create a note"]
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

    // ===== CREATE NOTE =====
    if (intentTokens.includes('note') && (intentTokens.includes('create') || intentTokens.includes('new') || intentTokens.includes('add') || intentTokens.includes('write'))) {
      console.log('🔍 Create note branch triggered');
      
      // Require authentication for note creation
      if (!userId) {
        return res.status(401).json({
          reply: "Please log in to create notes. You can still search notes using the BuildAssist chatbot without logging in.",
          error: true
        });
      }
      
      const noteDetails = parseNoteDetails(message);
      console.log('Parsed note details:', noteDetails);

      try {
        // If no title provided, guide the user with examples
        if (!noteDetails.title || noteDetails.title === 'Untitled Note') {
          return res.json({
            reply: `I'd love to create a note for you! Just include a title.\n\nHere are some ways you can do it:\n• Create note "Site Inspection Report"\n• Add note titled Foundation Review\n• New note "Safety Checklist" tag: urgent\n\nAvailable tags: Bug, Feature, Issue, Idea, Urgent, Important, Reminder, Todo`,
            type: "guide",
          });
        }

        // Validate content
        if (!noteDetails.content || noteDetails.content.length < 3) {
          return res.json({
            reply: "Your note content is too short. Please provide more details.",
          });
        }

        // Create through NoteService for proper user association & logging
        const newNote = await NoteService.createNote({
          title: noteDetails.title,
          content: noteDetails.content,
          tag: noteDetails.tag,
        }, userId);

        // Fire notification (same as REST endpoint)
        NotificationService.createNoteNotification(userId, {
          noteTitle: newNote.title,
          noteId: newNote.id,
          action: 'created',
          tag: newNote.tag,
        }).catch(() => {});

        return res.json({
          reply: `✅ Note created successfully!\n\n📝 **${newNote.title}**\n🏷️ Tag: ${newNote.tag}\n\n${noteDetails.content.substring(0, 100)}${noteDetails.content.length > 100 ? '...' : ''}`,
          type: "note_created",
          data: newNote,
          suggestions: ["Show my notes", "Create another note", "Show my tasks"]
        });

      } catch (error) {
        console.error('Error creating note:', error);
        // Check if it's a validation error from Mongoose
        if (error.name === 'ValidationError') {
          const messages = Object.values(error.errors).map(e => e.message);
          return res.status(400).json({
            reply: `Validation error: ${messages.join(', ')}. Please provide valid note details.`,
            error: true
          });
        }
        return res.status(500).json({
          reply: "Failed to create the note. Please try again or contact support.",
          error: true
        });
      }
    }

    // ===== ADD TASK =====
    if (intentTokens.includes('task') && (intentTokens.includes('add') || intentTokens.includes('create') || intentTokens.includes('new') || intentTokens.includes('assign'))) {
      console.log('🔍 Add task branch triggered');
      
      // Require authentication for task creation
      if (!userId) {
        return res.status(401).json({
          reply: "Please log in to create tasks. You can still view tasks using the BuildAssist chatbot without logging in.",
          error: true
        });
      }
      
      const taskDetails = parseTaskDetails(message);
      console.log('Parsed task details:', taskDetails);

      try {
        // If no title provided, guide the user with examples
        if (!taskDetails.title || taskDetails.title === 'New Task') {
          return res.json({
            reply: `I'd love to create a task for you! Just include a title.\n\nHere are some ways you can do it:\n• Add task "Review foundation plans"\n• Create task "Order steel beams" high priority\n• New task "Inspect wiring" due tomorrow\n• Add task "Safety audit" critical due next monday\n\nPriority options: low, medium, high, critical\nDue dates: today, tomorrow, next monday-saturday, or YYYY-MM-DD`,
            type: "guide",
          });
        }

        // Validate title length
        if (taskDetails.title.length < 3) {
          return res.json({
            reply: "Task title is too short. Please provide a more descriptive title.",
          });
        }

        // Convert dueDate if it's a date string
        let dueDate = null;
        if (taskDetails.dueDate) {
          try {
            dueDate = new Date(taskDetails.dueDate);
            if (isNaN(dueDate.getTime())) {
              dueDate = null;
            }
          } catch (e) {
            console.warn('Invalid date format:', taskDetails.dueDate);
            dueDate = null;
          }
        }
        
        // Create through TaskService for proper user association & logging
        const newTask = await TaskService.createTask({
          title: taskDetails.title,
          description: taskDetails.description,
          priority: taskDetails.priority,
          dueDate: dueDate,
          status: taskDetails.status,
          tags: [],
        }, userId);

        // Fire notification (same as REST endpoint)
        NotificationService.createTaskNotification(userId, {
          taskTitle: newTask.title,
          taskId: newTask.id,
          action: 'created',
        }).catch(() => {});

        const dueDateStr = dueDate ? dueDate.toLocaleDateString() : 'No due date';
        return res.json({
          reply: `✅ Task added successfully!\n\n✓ **${newTask.title}**\n🎯 Priority: ${taskDetails.priority}\n📅 Due: ${dueDateStr}\n\n${taskDetails.description.substring(0, 100)}${taskDetails.description.length > 100 ? '...' : ''}`,
          type: "task_added",
          data: newTask,
          suggestions: ["Show my tasks", "Create another task", "Show my notes"]
        });

      } catch (error) {
        console.error('Error adding task:', error);
        // Check if it's a validation error from Mongoose
        if (error.name === 'ValidationError') {
          const messages = Object.values(error.errors).map(e => e.message);
          return res.status(400).json({
            reply: `Validation error: ${messages.join(', ')}. Please provide valid task details.`,
            error: true
          });
        }
        return res.status(500).json({
          reply: "Failed to create the task. Please try again or contact support.",
          error: true
        });
      }
    }

    // ===== MEETINGS ====="
    if (intentTokens.includes('meeting') || intentTokens.includes('meetings') || intentTokens.includes('schedule') || intentTokens.includes('upcoming')) {
      console.log('🔍 Meeting branch triggered');
      
      if (!userId) {
        return res.status(401).json({
          reply: "Please log in to view your meetings. Your session may have expired — try logging in again.",
          error: true,
          suggestions: ["Show materials", "Material status"]
        });
      }
      
      const upcomingMeetings = await fetchUserMeetings(userId);
      console.log('   → meetings count', upcomingMeetings.length);
      return res.json({
        reply: upcomingMeetings.length > 0 
          ? `📅 You have ${upcomingMeetings.length} upcoming meeting${upcomingMeetings.length > 1 ? 's' : ''}:`
          : "You don't have any upcoming meetings. Would you like to schedule one?",
        data: upcomingMeetings,
        type: "meetings_data",
        suggestions: upcomingMeetings.length > 0 
          ? ["Schedule a meeting", "Show my tasks", "Dashboard summary"]
          : ["Schedule a meeting", "Show my tasks"]
      });
    }

    // ===== TASKS =====
    if (intentTokens.includes('task') || intentTokens.includes('tasks') || intentTokens.includes('todo') || intentTokens.includes('pending') || intentTokens.includes('stuck') || intentTokens.includes('blocked')) {
      console.log('🔍 Task branch triggered');
      
      if (!userId) {
        return res.status(401).json({
          reply: "Please log in to view your tasks. Your session may have expired — try logging in again.",
          error: true,
          suggestions: ["Show materials", "Material status"]
        });
      }
      
      const pendingTasks = await fetchUserTasks(userId);
      console.log('   → pendingTasks count', pendingTasks.length);
      return res.json({
        reply: pendingTasks.length > 0 
          ? `✅ You have ${pendingTasks.length} pending task${pendingTasks.length > 1 ? 's' : ''}:`
          : "No pending tasks — you're all caught up! 🎉",
        data: pendingTasks,
        type: "tasks_data",
        suggestions: pendingTasks.length > 0 
          ? ["Create a task", "Show my notes", "Dashboard summary"]
          : ["Create a task", "Show my meetings"]
      });
    }

    // ===== NOTES =====
    if (intentTokens.includes('note') || intentTokens.includes('notes') || intentTokens.includes('search')) {
      console.log('🔍 Notes branch triggered');
      
      if (!userId) {
        return res.status(401).json({
          reply: "Please log in to view your notes. Your session may have expired — try logging in again.",
          error: true,
          suggestions: ["Show materials", "Material status"]
        });
      }
      
      const keywords = tokens.filter(w => !['note','notes','search','find','my','all','our','get','fetch','view'].includes(w));
      const searchKeyword = keywords[0] || '';
      const noteResults = await fetchUserNotes(userId);
      const filtered = searchKeyword 
        ? noteResults.filter(note => note.title.toLowerCase().includes(searchKeyword) || note.content?.toLowerCase().includes(searchKeyword))
        : noteResults;
      console.log('   → noteResults count', filtered.length);
      return res.json({
        reply: filtered.length > 0 
          ? `📝 Found ${filtered.length} note${filtered.length > 1 ? 's' : ''}${searchKeyword ? ` matching "${searchKeyword}"` : ''}:`
          : searchKeyword 
            ? `No notes found matching "${searchKeyword}". Try a different keyword or create a new note.`
            : "You don't have any notes yet. Would you like to create one?",
        data: filtered.slice(0, 10),
        type: "notes_data",
        suggestions: filtered.length > 0 
          ? ["Create a note", "Show my tasks", "Dashboard summary"]
          : ["Create a note", "Show my tasks"]
      });
    }

    // ===== DASHBOARD =====
    if (intentTokens.includes('summary') || intentTokens.includes('dashboard')) {
      console.log('🔍 Dashboard branch triggered');
      
      if (!userId) {
        return res.status(401).json({
          reply: "Please log in to view your dashboard. Your session may have expired — try logging in again.",
          error: true,
          suggestions: ["Show materials", "Material status"]
        });
      }
      
      const summary = await getDashboardSummary(userId);
      console.log('   → dashboard summary', summary);
      return res.json({
        reply: `📊 **Project Dashboard**\n\n📅 Meetings: ${summary?.summary?.totalMeetings || 0}\n✅ Pending Tasks: ${summary?.summary?.pendingTasks || 0}\n📝 Notes: ${summary?.summary?.totalNotes || 0}`,
        data: summary,
        type: "dashboard_data",
        suggestions: ["Show my meetings", "Show my tasks", "Show my notes", "Material status"]
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

    // Procurement queries - check for SPECIFIC material keywords FIRST
    console.log('🔍 Procurement tokens:', tokens);
    console.log('   Total items parsed:', procurementItems.length);
    if (procurementItems.length > 0) {
      console.log('   First item sample:', JSON.stringify(procurementItems[0], null, 2));
    }

    // Check if user is asking for procurement/material data
    const isProcurementQuery = 
      intentTokens.includes('procurement') ||
      intentTokens.includes('material') ||
      intentTokens.includes('materials') ||
      lowerMessage.includes('show procurement status') ||
      lowerMessage.includes('material status');

    if (!isProcurementQuery) {
      // Not a procurement query at all - return help
      return res.json({
        reply: `I'm not sure what you're looking for. Here's what I can help with:\n\n📅 Meetings — "show my meetings" or "schedule a meeting"\n✅ Tasks — "show my tasks" or "add a task"\n📝 Notes — "show my notes" or "create a note"\n🏗️ Materials — "material status" or "show concrete"\n📊 Dashboard — "dashboard summary"`,
        type: "help",
        suggestions: ["Show my meetings", "Show my tasks", "Material status", "Dashboard summary"]
      });
    }

    // Strip generic procurement keywords to find the actual search terms
    const genericWords = ['procurement', 'material', 'materials', 'status', 'schedule', 'all', 'get', 'what', 'whats', 'check', 'find', 'search', 'look', 'up', 'my', 'our', 'is', 'are', 'have', 'has', 'do', 'does', 'can', 'i', 'we', 'any', 'available', 'current', 'update', 'latest'];
    const searchTokens = intentTokens.filter(t => !genericWords.includes(t));
    console.log('   Search tokens (after removing generic words):', searchTokens);

    // If no specific material/category keyword was provided, show all available materials
    if (searchTokens.length === 0) {
      const enrichedItems = await enrichProcurementItems(procurementItems.slice(0, 10), userId);
      const allCategories = [...new Set(
        procurementItems.map(item => item.category).filter(Boolean)
      )];
      let replyMsg = `Here are the available procurement materials (${procurementItems.length} total):`;
      if (allCategories.length > 0) {
        replyMsg += `\n\nCategories: ${allCategories.join(', ')}`;
      }
      console.log('✅ Returning all procurement items for generic query');
      return res.json({
        reply: replyMsg,
        data: enrichedItems,
        type: "procurement_data"
      });
    }

    // Build list of all known keywords for fuzzy matching
    const knownCategories = [
      'electrical', 'low voltage', 'protection', 'plumbing', 'hvac', 'civil', 
      'fire', 'elevator', 'concrete', 'glass', 'steel', 'generator', 'elv',
      'lightning', 'detection', 'system', 'delivery'
    ];
    const knownMaterials = [...new Set(
      procurementItems.map(item => item.material?.toLowerCase()).filter(Boolean)
    )];
    const allKnownWords = [...new Set([...knownCategories, ...knownMaterials])];

    // Auto-correct misspelled tokens using fuzzy matching
    const corrections = [];
    const correctedTokens = searchTokens.map(token => {
      // If token already matches exactly, keep it
      if (allKnownWords.some(w => w.includes(token) || token.includes(w))) {
        return token;
      }
      const fuzzy = fuzzyMatch(token, allKnownWords);
      if (fuzzy) {
        corrections.push({ from: token, to: fuzzy.match });
        console.log(`   🔧 Auto-corrected "${token}" → "${fuzzy.match}" (distance: ${fuzzy.distance})`);
        return fuzzy.match;
      }
      return token;
    });

    const correctionNote = corrections.length > 0
      ? `(Did you mean: ${corrections.map(c => `"${c.to}"` ).join(', ')}?)\n\n`
      : '';

    console.log('   Corrected tokens:', correctedTokens);

    // Now search with the corrected tokens
    let filteredItems = null;

    // Check for specific material keywords (first match only)
    if (!filteredItems && correctedTokens.includes('concrete')) {
      filteredItems = procurementItems.filter(item => item.material?.toLowerCase().includes('concrete'));
      console.log('   concrete items count', filteredItems.length);
    }

    if (!filteredItems && correctedTokens.includes('delivery')) {
      filteredItems = procurementItems.filter(item => item.revisedDelivery);
      console.log('   delivery items count', filteredItems.length);
    }

    // Check for category keywords (only if no specific keyword matched yet)
    if (!filteredItems) {
      for (const cat of knownCategories) {
        if (correctedTokens.includes(cat)) {
          filteredItems = procurementItems.filter(item => 
            item.category?.toLowerCase().includes(cat) ||
            item.parentCategory?.toLowerCase().includes(cat) ||
            item.material?.toLowerCase().includes(cat)
          );
          console.log(`   category/material "${cat}" matched, count`, filteredItems.length);
          break;
        }
      }
    }

    // Generic search using corrected tokens
    if (!filteredItems) {
      filteredItems = procurementItems.filter(item =>
        correctedTokens.some(term =>
          item.material?.toLowerCase().includes(term) ||
          item.category?.toLowerCase().includes(term)
        )
      );
      console.log('   generic search results count', filteredItems.length);
    }

    // Return filtered results
    if (filteredItems && filteredItems.length > 0) {
      const enrichedItems = await enrichProcurementItems(filteredItems.slice(0, 10), userId);
      console.log('✅ Returning procurement_data');
      console.log('Sending items:', enrichedItems.length);
      return res.json({
        reply: `${correctionNote}Found ${filteredItems.length} matching items:`,
        data: enrichedItems,
        type: "procurement_data"
      });
    }

    // No matching items found - show available categories/materials
    const availableCategories = [...new Set(
      procurementItems
        .map(item => item.category)
        .filter(Boolean)
    )];
    const sampleMaterials = [...new Set(
      procurementItems
        .slice(0, 30)
        .map(item => item.material)
        .filter(Boolean)
    )].slice(0, 10);

    let replyMsg = `No procurement items found matching "${searchTokens.join(' ')}".`;
    if (availableCategories.length > 0) {
      replyMsg += `\n\nAvailable categories:\n${availableCategories.map(c => `• ${c}`).join('\n')}`;
    }
    if (sampleMaterials.length > 0) {
      replyMsg += `\n\nSome available materials:\n${sampleMaterials.map(m => `• ${m}`).join('\n')}`;
    }
    replyMsg += `\n\nTry asking for one of these instead.`;

    return res.json({
      reply: replyMsg,
      type: "text"
    });

  } catch (error) {
    console.error("Error:", error.message);
    return res.status(500).json({ reply: "Error processing request", error: true });
  }
};