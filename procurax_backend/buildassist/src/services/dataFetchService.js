import MeetingService from "../../../core/services/meeting.service.js";
import NoteService from "../../../core/services/note.service.js";
import TaskService from "../../../core/services/task.service.js";
import logger from "../../../core/logging/logger.js";

/**
 * ============================================
 * VALIDATION & HELPER USER-DEFINED FUNCTIONS
 * ============================================
 */

/**
 * User-defined function: Validate user ID
 */
const validateUserId = (userId) => {
  if (!userId) {
    throw new Error("User ID is required");
  }
  return userId;
};

/**
 * User-defined function: Escape special regex characters in a string
 */
const escapeRegex = (string) => {
  if (!string) return '';
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
};

/**
 * ============================================
 * DATA NORMALIZATION USER-DEFINED FUNCTIONS
 * ============================================
 */

/**
 * User-defined function: Normalize meeting data for consistent output
 */
const normalizeMeetingData = (meeting) => {
  if (!meeting) return null;
  return {
    id: meeting.id || meeting._id?.toString() || '',
    title: meeting.title || '',
    description: meeting.description || '',
    location: meeting.location || '',
    startTime: meeting.startTime ? new Date(meeting.startTime) : null,
    endTime: meeting.endTime ? new Date(meeting.endTime) : null,
    priority: meeting.priority || 'medium',
    done: Boolean(meeting.done),
    type: 'meeting'
  };
};

/**
 * User-defined function: Normalize note data for consistent output
 */
const normalizeNoteData = (note) => {
  if (!note) return null;
  return {
    id: note.id || note._id?.toString() || '',
    title: note.title || '',
    content: note.content || '',
    tag: note.tag || '',
    createdAt: note.createdAt ? new Date(note.createdAt) : null,
    lastEdited: note.lastEdited ? new Date(note.lastEdited) : null,
    hasAttachment: Boolean(note.hasAttachment),
    type: 'note'
  };
};

/**
 * User-defined function: Normalize task data for consistent output
 */
const normalizeTaskData = (task) => {
  if (!task) return null;
  return {
    id: task.id || task._id?.toString() || '',
    title: task.title || '',
    description: task.description || '',
    status: task.status || 'todo',
    priority: task.priority || 'medium',
    dueDate: task.dueDate ? new Date(task.dueDate) : null,
    assignee: task.assignee || '',
    tags: Array.isArray(task.tags) ? task.tags : [],
    archived: Boolean(task.archived || task.isArchived),
    type: 'task'
  };
};

/**
 * ============================================
 * FETCH USER-DEFINED FUNCTIONS
 * ============================================
 */

/**
 * User-defined function: Fetch all meetings for a user
 * @param {string} userId - The user ID
 * @returns {Promise<Array>} Array of normalized meeting objects
 */
export const fetchUserMeetings = async (userId) => {
  try {
    validateUserId(userId);
    
    const result = await MeetingService.getMeetings(userId, { 
      limit: 1000,
      page: 1
    });
    
    if (!result || !Array.isArray(result.meetings)) {
      logger.warn("Invalid response from MeetingService", { userId });
      return [];
    }
    
    return result.meetings
      .map(normalizeMeetingData)
      .filter(m => m !== null);
  } catch (error) {
    logger.error("Error fetching meetings", { 
      userId, 
      error: error.message 
    });
    return [];
  }
};

/**
 * User-defined function: Fetch all notes for a user
 * @param {string} userId - The user ID
 * @returns {Promise<Array>} Array of normalized note objects
 */
export const fetchUserNotes = async (userId) => {
  try {
    validateUserId(userId);
    
    const result = await NoteService.getNotes(userId, { 
      limit: 1000,
      page: 1
    });
    
    if (!result || !Array.isArray(result.notes)) {
      logger.warn("Invalid response from NoteService", { userId });
      return [];
    }
    
    return result.notes
      .map(normalizeNoteData)
      .filter(n => n !== null);
  } catch (error) {
    logger.error("Error fetching notes", { 
      userId, 
      error: error.message 
    });
    return [];
  }
};

/**
 * User-defined function: Fetch all tasks for a user
 * @param {string} userId - The user ID
 * @returns {Promise<Array>} Array of normalized task objects
 */
export const fetchUserTasks = async (userId) => {
  try {
    validateUserId(userId);
    
    const result = await TaskService.getTasks(userId, { 
      archived: false,
      limit: 1000,
      page: 1
    });
    
    if (!result || !Array.isArray(result.tasks)) {
      logger.warn("Invalid response from TaskService", { userId });
      return [];
    }
    
    return result.tasks
      .map(normalizeTaskData)
      .filter(t => t !== null);
  } catch (error) {
    logger.error("Error fetching tasks", { 
      userId, 
      error: error.message 
    });
    return [];
  }
};

/**
 * User-defined function: Fetch upcoming meetings (next 7 days)
 * @param {string} userId - The user ID
 * @returns {Promise<Array>} Array of upcoming meetings
 */
export const fetchUpcomingMeetings = async (userId) => {
  try {
    validateUserId(userId);
    
    const now = new Date();
    const sevenDaysLater = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    
    const result = await MeetingService.getMeetings(userId, { 
      startDate: now.toISOString(),
      endDate: sevenDaysLater.toISOString(),
      limit: 1000,
      page: 1
    });
    
    if (!result || !Array.isArray(result.meetings)) {
      logger.warn("Invalid response from MeetingService", { userId });
      return [];
    }
    
    return result.meetings
      .map(normalizeMeetingData)
      .filter(m => m !== null && m.startTime <= sevenDaysLater)
      .sort((a, b) => a.startTime - b.startTime);
  } catch (error) {
    logger.error("Error fetching upcoming meetings", { 
      userId, 
      error: error.message 
    });
    return [];
  }
};

/**
 * User-defined function: Fetch pending and in-progress tasks
 * @param {string} userId - The user ID
 * @returns {Promise<Array>} Array of pending tasks
 */
export const fetchPendingTasks = async (userId) => {
  try {
    validateUserId(userId);
    
    // Fetch all non-archived tasks
    const result = await TaskService.getTasks(userId, { 
      archived: false,
      limit: 1000,
      page: 1
    });
    
    if (!result || !Array.isArray(result.tasks)) {
      logger.warn("Invalid response from TaskService", { userId });
      return [];
    }
    
    // Filter for pending and in-progress status
    return result.tasks
      .filter(task => ['todo', 'in_progress', 'blocked'].includes(task.status))
      .map(normalizeTaskData)
      .filter(t => t !== null)
      .sort((a, b) => {
        // Sort by dueDate if available, otherwise by priority
        if (a.dueDate && b.dueDate) {
          return new Date(a.dueDate) - new Date(b.dueDate);
        }
        const priorityOrder = { high: 0, medium: 1, low: 2 };
        return (priorityOrder[a.priority] || 3) - (priorityOrder[b.priority] || 3);
      });
  } catch (error) {
    logger.error("Error fetching pending tasks", { 
      userId, 
      error: error.message 
    });
    return [];
  }
};
/**
 * ============================================
 * SEARCH USER-DEFINED FUNCTIONS
 * ============================================
 */

/**
 * User-defined function: Search notes by keyword
 * @param {string} userId - The user ID
 * @param {string} keyword - The search keyword
 * @returns {Promise<Array>} Array of matching notes
 */
export const searchNotes = async (userId, keyword) => {
  try {
    validateUserId(userId);
    
    if (!keyword || keyword.trim() === '') {
      return [];
    }
    
    const searchKeyword = keyword.trim().toLowerCase();
    const result = await NoteService.getNotes(userId, { limit: 1000, page: 1 });
    
    if (!result || !Array.isArray(result.notes)) {
      return [];
    }
    
    return result.notes
      .filter(note => 
        note.title?.toLowerCase().includes(searchKeyword) ||
        note.content?.toLowerCase().includes(searchKeyword) ||
        note.tag?.toLowerCase().includes(searchKeyword)
      )
      .slice(0, 10)
      .map(note => ({
        id: note.id || note._id?.toString(),
        title: note.title || '',
        content: (note.content || '').substring(0, 200),
        tag: note.tag || '',
        createdAt: note.createdAt,
        type: 'note'
      }));
  } catch (error) {
    logger.error("Error searching notes", { 
      userId, 
      keyword,
      error: error.message 
    });
    return [];
  }
};

/**
 * User-defined function: Search tasks by keyword
 * @param {string} userId - The user ID
 * @param {string} keyword - The search keyword
 * @returns {Promise<Array>} Array of matching tasks
 */
export const searchTasks = async (userId, keyword) => {
  try {
    validateUserId(userId);
    
    if (!keyword || keyword.trim() === '') {
      return [];
    }
    
    const searchKeyword = keyword.trim().toLowerCase();
    const result = await TaskService.getTasks(userId, { archived: false, limit: 1000, page: 1 });
    
    if (!result || !Array.isArray(result.tasks)) {
      return [];
    }
    
    return result.tasks
      .filter(task => 
        task.title?.toLowerCase().includes(searchKeyword) ||
        task.description?.toLowerCase().includes(searchKeyword) ||
        (Array.isArray(task.tags) && task.tags.some(tag => tag?.toLowerCase().includes(searchKeyword)))
      )
      .slice(0, 10)
      .map(task => ({
        id: task.id || task._id?.toString(),
        title: task.title || '',
        description: task.description || '',
        status: task.status || 'todo',
        priority: task.priority || 'medium',
        dueDate: task.dueDate,
        type: 'task'
      }));
  } catch (error) {
    logger.error("Error searching tasks", { 
      userId, 
      keyword,
      error: error.message 
    });
    return [];
  }
};

/**
 * User-defined function: Search meetings by keyword
 * @param {string} userId - The user ID
 * @param {string} keyword - The search keyword
 * @returns {Promise<Array>} Array of matching meetings
 */
export const searchMeetings = async (userId, keyword) => {
  try {
    validateUserId(userId);
    
    if (!keyword || keyword.trim() === '') {
      return [];
    }
    
    const searchKeyword = keyword.trim().toLowerCase();
    const result = await MeetingService.getMeetings(userId, { limit: 1000, page: 1 });
    
    if (!result || !Array.isArray(result.meetings)) {
      return [];
    }
    
    return result.meetings
      .filter(meeting => 
        meeting.title?.toLowerCase().includes(searchKeyword) ||
        meeting.description?.toLowerCase().includes(searchKeyword)
      )
      .slice(0, 5)
      .map(normalizeMeetingData)
      .filter(m => m !== null);
  } catch (error) {
    logger.error("Error searching meetings", { 
      userId, 
      keyword,
      error: error.message 
    });
    return [];
  }
};


/**
 * ============================================
 * DASHBOARD USER-DEFINED FUNCTIONS
 * ============================================
 */

/**
 * User-defined function: Get dashboard summary for user
 * @param {string} userId - The user ID
 * @returns {Promise<Object>} Dashboard summary with counts and upcoming items
 */
export const getDashboardSummary = async (userId) => {
  try {
    validateUserId(userId);
    
    // Fetch all data in parallel
    const [meetingsResult, notesResult, tasksResult] = await Promise.all([
      MeetingService.getMeetings(userId, { limit: 1000, page: 1 }).catch(err => {
        logger.error("Error fetching meetings for dashboard", { userId, error: err.message });
        return { meetings: [] };
      }),
      NoteService.getNotes(userId, { limit: 1000, page: 1 }).catch(err => {
        logger.error("Error fetching notes for dashboard", { userId, error: err.message });
        return { notes: [] };
      }),
      TaskService.getTasks(userId, { archived: false, limit: 1000, page: 1 }).catch(err => {
        logger.error("Error fetching tasks for dashboard", { userId, error: err.message });
        return { tasks: [] };
      })
    ]);
    
    const meetings = Array.isArray(meetingsResult?.meetings) ? meetingsResult.meetings : [];
    const notes = Array.isArray(notesResult?.notes) ? notesResult.notes : [];
    const tasks = Array.isArray(tasksResult?.tasks) ? tasksResult.tasks : [];
    
    // Calculate statistics
    const pendingTasks = tasks.filter(t => 
      ['todo', 'in_progress', 'blocked'].includes(t.status)
    ).length;
    
    const completedTasks = tasks.filter(t => t.status === 'done').length;
    
    // Get upcoming items
    const upcomingMeetings = await fetchUpcomingMeetings(userId);
    const pendingTasksList = await fetchPendingTasks(userId);
    
    return {
      success: true,
      summary: {
        totalMeetings: meetings.length,
        totalNotes: notes.length,
        pendingTasks,
        completedTasks,
        totalTasks: tasks.length
      },
      upcoming: {
        meetings: upcomingMeetings.slice(0, 3),
        tasks: pendingTasksList.slice(0, 3)
      }
    };
  } catch (error) {
    logger.error("Error getting dashboard summary", { 
      userId, 
      error: error.message 
    });
    return {
      success: false,
      summary: {
        totalMeetings: 0,
        totalNotes: 0,
        pendingTasks: 0,
        completedTasks: 0,
        totalTasks: 0
      },
      upcoming: {
        meetings: [],
        tasks: []
      }
    };
  }
};
