/**
 * Meeting Service
 * 
 * Business logic layer for meeting operations.
 * Includes conflict detection and scheduling suggestions.
 */

import Meeting from "../../meetings/models/Meeting.js";
import { AppError } from "../errors/AppError.js";
import logger from "../logging/logger.js";

class MeetingService {
  /**
   * Create a new meeting with conflict detection
   */
  async createMeeting(data, userId) {
    logger.debug("Creating meeting", { userId, title: data.title });

    const { startTime, endTime } = data;

    // Check for conflicts
    const conflicts = await this.findConflicts(
      new Date(startTime),
      new Date(endTime),
      null,
      userId
    );

    if (conflicts.length > 0) {
      const suggestion = await this.suggestNextSlot(startTime, userId);
      throw new AppError(
        "Meeting time conflicts with existing meetings",
        409,
        "MEETING_CONFLICT",
        { conflicts, suggestion }
      );
    }

    const meeting = new Meeting({
      ...data,
      startTime: new Date(startTime),
      endTime: new Date(endTime),
      owner: userId,
    });

    await meeting.save();

    logger.info("Meeting created", { meetingId: meeting._id, userId });
    return this.normalizeMeeting(meeting);
  }

  /**
   * Get all meetings for a user
   */
  async getMeetings(userId, options = {}) {
    const { done, startDate, endDate, page = 1, limit = 50 } = options;

    const query = { owner: userId };

    if (typeof done === "boolean") {
      query.done = done;
    }

    if (startDate || endDate) {
      query.startTime = {};
      if (startDate) query.startTime.$gte = new Date(startDate);
      if (endDate) query.startTime.$lte = new Date(endDate);
    }

    const meetings = await Meeting.find(query)
      .sort({ startTime: 1 })
      .skip((page - 1) * limit)
      .limit(limit);

    const total = await Meeting.countDocuments(query);

    return {
      meetings: meetings.map((m) => this.normalizeMeeting(m)),
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get a single meeting by ID
   */
  async getMeetingById(meetingId, userId) {
    const meeting = await Meeting.findOne({ _id: meetingId, owner: userId });

    if (!meeting) {
      throw AppError.notFound("Meeting");
    }

    return this.normalizeMeeting(meeting);
  }

  /**
   * Update a meeting
   */
  async updateMeeting(meetingId, userId, updates) {
    logger.debug("Updating meeting", { meetingId, userId });

    // If updating times, check for conflicts
    if (updates.startTime || updates.endTime) {
      const existing = await Meeting.findOne({ _id: meetingId, owner: userId });
      if (!existing) throw AppError.notFound("Meeting");

      const newStart = updates.startTime ? new Date(updates.startTime) : existing.startTime;
      const newEnd = updates.endTime ? new Date(updates.endTime) : existing.endTime;

      const conflicts = await this.findConflicts(newStart, newEnd, meetingId, userId);
      if (conflicts.length > 0) {
        throw new AppError(
          "Updated time conflicts with existing meetings",
          409,
          "MEETING_CONFLICT",
          { conflicts }
        );
      }
    }

    const meeting = await Meeting.findOneAndUpdate(
      { _id: meetingId, owner: userId },
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!meeting) {
      throw AppError.notFound("Meeting");
    }

    logger.info("Meeting updated", { meetingId, userId });
    return this.normalizeMeeting(meeting);
  }

  /**
   * Mark meeting as done
   */
  async markMeetingDone(meetingId, userId, done = true) {
    const meeting = await Meeting.findOneAndUpdate(
      { _id: meetingId, owner: userId },
      { $set: { done } },
      { new: true }
    );

    if (!meeting) {
      throw AppError.notFound("Meeting");
    }

    logger.info("Meeting marked as done", { meetingId, userId, done });
    return this.normalizeMeeting(meeting);
  }

  /**
   * Delete a meeting
   */
  async deleteMeeting(meetingId, userId) {
    const meeting = await Meeting.findOneAndDelete({ _id: meetingId, owner: userId });

    if (!meeting) {
      throw AppError.notFound("Meeting");
    }

    logger.info("Meeting deleted", { meetingId, userId });
    return { success: true };
  }

  /**
   * Find conflicting meetings
   */
  async findConflicts(startTime, endTime, excludeMeetingId, userId) {
    const query = {
      owner: userId,
      $or: [
        { startTime: { $lt: endTime, $gte: startTime } },
        { endTime: { $gt: startTime, $lte: endTime } },
        { startTime: { $lte: startTime }, endTime: { $gte: endTime } },
      ],
    };

    if (excludeMeetingId) {
      query._id = { $ne: excludeMeetingId };
    }

    const conflicts = await Meeting.find(query).select("title startTime endTime");
    return conflicts.map((c) => ({
      id: c._id.toString(),
      title: c.title,
      startTime: c.startTime,
      endTime: c.endTime,
    }));
  }

  /**
   * Suggest next available time slot
   */
  async suggestNextSlot(requestedStartTime, userId) {
    const startOfDay = new Date(requestedStartTime);
    startOfDay.setHours(9, 0, 0, 0);

    const endOfDay = new Date(requestedStartTime);
    endOfDay.setHours(18, 0, 0, 0);

    const meetings = await Meeting.find({
      owner: userId,
      startTime: { $gte: startOfDay, $lt: endOfDay },
    }).sort({ startTime: 1 });

    // Find first 1-hour gap
    let suggestedStart = startOfDay;
    for (const meeting of meetings) {
      if (suggestedStart < meeting.startTime) {
        const gap = (meeting.startTime - suggestedStart) / (1000 * 60);
        if (gap >= 60) {
          return {
            startTime: suggestedStart,
            endTime: new Date(suggestedStart.getTime() + 60 * 60 * 1000),
          };
        }
      }
      suggestedStart = new Date(Math.max(suggestedStart, meeting.endTime));
    }

    // Check remaining time until end of day
    if (suggestedStart < endOfDay) {
      return {
        startTime: suggestedStart,
        endTime: new Date(Math.min(suggestedStart.getTime() + 60 * 60 * 1000, endOfDay)),
      };
    }

    // No slot today, suggest next day
    const nextDay = new Date(requestedStartTime);
    nextDay.setDate(nextDay.getDate() + 1);
    nextDay.setHours(9, 0, 0, 0);

    return {
      startTime: nextDay,
      endTime: new Date(nextDay.getTime() + 60 * 60 * 1000),
    };
  }

  /**
   * Get upcoming meetings
   */
  async getUpcomingMeetings(userId, limit = 5) {
    const now = new Date();
    const meetings = await Meeting.find({
      owner: userId,
      startTime: { $gte: now },
      done: false,
    })
      .sort({ startTime: 1 })
      .limit(limit);

    return meetings.map((m) => this.normalizeMeeting(m));
  }

  /**
   * Normalize meeting object for API response
   */
  normalizeMeeting(meeting) {
    return {
      id: meeting._id.toString(),
      title: meeting.title,
      description: meeting.description,
      location: meeting.location,
      startTime: meeting.startTime,
      endTime: meeting.endTime,
      priority: meeting.priority,
      done: meeting.done,
      createdAt: meeting.createdAt,
      updatedAt: meeting.updatedAt,
    };
  }
}

export default new MeetingService();
