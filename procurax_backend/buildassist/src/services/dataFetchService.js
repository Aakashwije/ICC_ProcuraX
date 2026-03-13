import Meeting from "../../../meetings/models/Meeting.js";
import Note from "../../../notes/notes.model.js";
import Task from "../../../tasks/tasks.model.js";

/**
 * Fetch all meetings for a user
 */
export const fetchUserMeetings = async (userId) => {
  try {
    const filter = userId ? { owner: userId } : {}; // if no userId return all
    const meetings = await Meeting.find(filter)
      .sort({ startTime: 1 })
      .lean();
    
    return meetings.map(meeting => ({
      id: meeting._id.toString(),
      title: meeting.title,
      description: meeting.description,
      location: meeting.location,
      startTime: meeting.startTime,
      endTime: meeting.endTime,
      priority: meeting.priority,
      done: meeting.done,
      type: 'meeting'
    }));
  } catch (error) {
    console.error("Error fetching meetings:", error.message);
    return [];
  }
};

/**
 * Fetch all notes for a user
 */
export const fetchUserNotes = async (userId) => {
  try {
    const filter = userId ? { owner: userId } : {};
    const notes = await Note.find(filter)
      .sort({ createdAt: -1 })
      .lean();
    
    return notes.map(note => ({
      id: note._id.toString(),
      title: note.title,
      content: note.content,
      tag: note.tag,
      createdAt: note.createdAt,
      lastEdited: note.lastEdited,
      hasAttachment: note.hasAttachment,
      type: 'note'
    }));
  } catch (error) {
    console.error("Error fetching notes:", error.message);
    return [];
  }
};

/**
 * Fetch all tasks for a user
 */
export const fetchUserTasks = async (userId) => {
  try {
    const filter = userId ? { owner: userId } : {};
    const tasks = await Task.find(filter)
      .sort({ dueDate: 1 })
      .lean();
    
    return tasks.map(task => ({
      id: task._id.toString(),
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      dueDate: task.dueDate,
      assignee: task.assignee,
      tags: task.tags,
      archived: task.archived || false,
      type: 'task'
    }));
  } catch (error) {
    console.error("Error fetching tasks:", error.message);
    return [];
  }
};

/**
 * Fetch upcoming meetings (next 7 days)
 */
export const fetchUpcomingMeetings = async (userId) => {
  try {
    const now = new Date();
    const sevenDaysLater = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    
    const filter = userId
      ? { owner: userId, startTime: { $gte: now, $lte: sevenDaysLater } }
      : { startTime: { $gte: now, $lte: sevenDaysLater } };
    
    const meetings = await Meeting.find(filter)
      .sort({ startTime: 1 })
      .lean();
    
    return meetings.map(meeting => ({
      id: meeting._id.toString(),
      title: meeting.title,
      description: meeting.description,
      location: meeting.location,
      startTime: meeting.startTime,
      endTime: meeting.endTime,
      priority: meeting.priority,
      done: meeting.done,
      type: 'meeting'
    }));
  } catch (error) {
    console.error("Error fetching upcoming meetings:", error.message);
    return [];
  }
};

/**
 * Fetch overdue and pending tasks
 */
export const fetchPendingTasks = async (userId) => {
  try {
    const filter = {
      status: { $in: ['todo', 'in_progress', 'blocked'] },
      archived: { $ne: true }
    };
    if (userId) filter.owner = userId;
    const tasks = await Task.find(filter)
      .sort({ dueDate: 1 })
      .lean();
    
    return tasks.map(task => ({
      id: task._id.toString(),
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      dueDate: task.dueDate,
      assignee: task.assignee,
      tags: task.tags,
      type: 'task'
    }));
  } catch (error) {
    console.error("Error fetching pending tasks:", error.message);
    return [];
  }
};

/**
 * Search notes by keyword
 */
export const searchNotes = async (userId, keyword) => {
  try {
    const filter = {
      $or: [
        { title: { $regex: keyword, $options: 'i' } },
        { content: { $regex: keyword, $options: 'i' } },
        { tag: { $regex: keyword, $options: 'i' } }
      ]
    };
    if (userId) filter.owner = userId;
    const notes = await Note.find(filter)
      .sort({ createdAt: -1 })
      .limit(10)
      .lean();
    
    return notes.map(note => ({
      id: note._id.toString(),
      title: note.title,
      content: note.content.substring(0, 200), // First 200 chars
      tag: note.tag,
      createdAt: note.createdAt,
      type: 'note'
    }));
  } catch (error) {
    console.error("Error searching notes:", error.message);
    return [];
  }
};

/**
 * Search tasks by keyword
 */
export const searchTasks = async (userId, keyword) => {
  try {
    const filter = {
      $or: [
        { title: { $regex: keyword, $options: 'i' } },
        { description: { $regex: keyword, $options: 'i' } },
        { tags: { $in: [new RegExp(keyword, 'i')] } }
      ],
      archived: { $ne: true }
    };
    if (userId) filter.owner = userId;
    const tasks = await Task.find(filter)
      .sort({ dueDate: 1 })
      .limit(10)
      .lean();
    
    return tasks.map(task => ({
      id: task._id.toString(),
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      dueDate: task.dueDate,
      type: 'task'
    }));
  } catch (error) {
    console.error("Error searching tasks:", error.message);
    return [];
  }
};

/**
 * Get dashboard summary for user
 */
export const getDashboardSummary = async (userId) => {
  try {
    const meetingFilter = userId ? { owner: userId } : {};
    const noteFilter = userId ? { owner: userId } : {};
    const taskFilter = userId ? { owner: userId } : {};

    const meetings = await Meeting.countDocuments(meetingFilter);
    const notes = await Note.countDocuments(noteFilter);
    const pendingTasks = await Task.countDocuments({ 
      ...taskFilter,
      status: { $in: ['todo', 'in_progress', 'blocked'] },
      archived: { $ne: true }
    });
    const completedTasks = await Task.countDocuments({ 
      ...taskFilter,
      status: 'done' 
    });
    
    const upcomingMeetings = await fetchUpcomingMeetings(userId);
    const pendingTasksList = await fetchPendingTasks(userId);
    
    return {
      summary: {
        totalMeetings: meetings,
        totalNotes: notes,
        pendingTasks,
        completedTasks,
      },
      upcoming: {
        meetings: upcomingMeetings.slice(0, 3),
        tasks: pendingTasksList.slice(0, 3)
      }
    };
  } catch (error) {
    console.error("Error getting dashboard summary:", error.message);
    return null;
  }
};
