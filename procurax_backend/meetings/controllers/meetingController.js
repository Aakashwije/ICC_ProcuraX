const Meeting = require("../models/Meeting");
const {
  findConflicts,
  suggestNextSlot,
} = require("../services/meetingService");

/**
 * ===========================
 * CREATE MEETING
 * ===========================
 */
exports.createMeeting = async (req, res) => {
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

    // Check overlapping meetings
    const conflicts = await findConflicts(startTime, endTime);

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
      startTime,
      endTime,
      location,
      done,
    });

    res.status(201).json(meeting);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * ===========================
 * GET ALL MEETINGS
 * (search, filter, sort)
 * ===========================
 */
exports.getMeetings = async (req, res) => {
  try {
    const { title, from, to, done } = req.query;
    const query = {};

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
exports.getMeetingById = async (req, res) => {
  try {
    const meeting = await Meeting.findById(req.params.id);

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
exports.updateMeeting = async (req, res) => {
  try {
    const { startTime, endTime } = req.body;

    if (startTime && endTime) {
      const conflicts = await findConflicts(
        startTime,
        endTime,
        req.params.id
      );

      if (conflicts.length > 0) {
        return res.status(409).json({
          message: "Reschedule conflict detected",
          conflicts,
        });
      }
    }

    const updatedMeeting = await Meeting.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    if (!updatedMeeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

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
exports.markMeetingDone = async (req, res) => {
  try {
    const meeting = await Meeting.findByIdAndUpdate(
      req.params.id,
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
exports.deleteMeeting = async (req, res) => {
  try {
    const meeting = await Meeting.findByIdAndDelete(req.params.id);

    if (!meeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    res.json({ message: "Meeting deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
