import Meeting from "../models/Meeting.js";
import { findConflicts, suggestNextSlot } from "../services/meetingService.js";

/**
 * ===========================
 * CREATE MEETING
 * ===========================
 */
export const createMeeting = async (req, res) => {
  try {
    const {
      title,
      description,
      startTime,
      endTime,
      location,
      done = false,
    } = req.body;

    if (!title || !startTime || !endTime) {
      return res.status(400).json({
        message: "Title, startTime and endTime are required",
      });
    }

    const parsedStart = new Date(startTime);
    const parsedEnd = new Date(endTime);

    if (Number.isNaN(parsedStart.getTime()) || Number.isNaN(parsedEnd.getTime())) {
      return res.status(400).json({
        message: "Invalid startTime or endTime",
      });
    }

    if (parsedStart >= parsedEnd) {
      return res.status(400).json({
        message: "startTime must be before endTime",
      });
    }

    // Check overlapping meetings for this user only
    const conflicts = await findConflicts(parsedStart, parsedEnd, null, req.userId);

    if (conflicts.length > 0) {
      const suggestion = await suggestNextSlot(startTime);

      return res.status(409).json({
        message: "Meeting time conflicts with existing meetings",
        conflicts,
        suggestion,
      });
    }

    const meeting = await Meeting.create({
      title,
      description,
      startTime: parsedStart,
      endTime: parsedEnd,
      location,
      done,
      owner: req.userId,
    });

    res.status(201).json(meeting);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * ===========================
 * GET ALL MEETINGS
 * (search, filter, sort — scoped to logged-in user)
 * ===========================
 */
export const getMeetings = async (req, res) => {
  try {
    const { title, from, to, done } = req.query;
    const query = { owner: req.userId };

    if (title) {
      query.title = new RegExp(title, "i");
    }

    if (from && to) {
      query.startTime = { $gte: new Date(from) };
      query.endTime = { $lte: new Date(to) };
    }

    if (done !== undefined) {
      query.done = done === "true";
    }

    const meetings = await Meeting.find(query).sort({ startTime: 1 });
    res.json(meetings);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * ===========================
 * GET SINGLE MEETING BY ID
 * ===========================
 */
export const getMeetingById = async (req, res) => {
  try {
    const meeting = await Meeting.findOne({ _id: req.params.id, owner: req.userId });

    if (!meeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    res.json(meeting);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * ===========================
 * UPDATE / RESCHEDULE MEETING
 * ===========================
 */
export const updateMeeting = async (req, res) => {
  try {
    const { startTime, endTime } = req.body;

    // Only allow owner to update their meeting
    const existingMeeting = await Meeting.findOne({ _id: req.params.id, owner: req.userId });

    if (!existingMeeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    const parsedStart = startTime ? new Date(startTime) : existingMeeting.startTime;
    const parsedEnd = endTime ? new Date(endTime) : existingMeeting.endTime;

    if (Number.isNaN(parsedStart.getTime()) || Number.isNaN(parsedEnd.getTime())) {
      return res.status(400).json({
        message: "Invalid startTime or endTime",
      });
    }

    if (parsedStart >= parsedEnd) {
      return res.status(400).json({
        message: "startTime must be before endTime",
      });
    }

    const conflicts = await findConflicts(parsedStart, parsedEnd, req.params.id, req.userId);

    if (conflicts.length > 0) {
      return res.status(409).json({
        message: "Reschedule conflict detected",
        conflicts,
      });
    }

    const updatedMeeting = await Meeting.findOneAndUpdate(
      { _id: req.params.id, owner: req.userId },
      {
        ...req.body,
        startTime: parsedStart,
        endTime: parsedEnd,
      },
      { new: true }
    );

    res.json(updatedMeeting);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * ===========================
 * MARK MEETING AS DONE
 * ===========================
 */
export const markMeetingDone = async (req, res) => {
  try {
    const meeting = await Meeting.findOneAndUpdate(
      { _id: req.params.id, owner: req.userId },
      { done: true },
      { new: true }
    );

    if (!meeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    res.json(meeting);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * ===========================
 * DELETE MEETING
 * ===========================
 */
export const deleteMeeting = async (req, res) => {
  try {
    const meeting = await Meeting.findOneAndDelete({ _id: req.params.id, owner: req.userId });

    if (!meeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    res.json({ message: "Meeting deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
