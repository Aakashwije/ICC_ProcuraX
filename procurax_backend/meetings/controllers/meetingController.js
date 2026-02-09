const Meeting = require("../models/Meeting");
const {
  findConflicts,
  suggestNextSlot
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
      done
    } = req.body;

    // Check time conflicts for this user
    const conflicts = await findConflicts(
      startTime,
      endTime,
      req.user._id
    );

    if (conflicts.length > 0) {
      const suggestion = await suggestNextSlot(
        startTime,
        req.user._id
      );

      return res.status(409).json({
        message: "Meeting time conflicts with existing meetings",
        conflicts,
        suggestion
      });
    }

    const meeting = await Meeting.create({
      title,
      description,
      startTime,
      endTime,
      location,
      done,
      createdBy: req.user._id // AUTO from JWT
    });

    res.status(201).json(meeting);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * ===========================
 * GET ALL MEETINGS (SECURE)
 * ===========================
 */
exports.getMeetings = async (req, res) => {
  try {
    const { title, from, to, done } = req.query;
    const query = { createdBy: req.user._id };

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
 * GET SINGLE MEETING
 * ===========================
 */
exports.getMeetingById = async (req, res) => {
  try {
    const meeting = await Meeting.findOne({
      _id: req.params.id,
      createdBy: req.user._id
    });

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
        req.user._id,
        req.params.id
      );

      if (conflicts.length > 0) {
        return res.status(409).json({
          message: "Reschedule conflict detected",
          conflicts
        });
      }
    }

    const updatedMeeting = await Meeting.findOneAndUpdate(
      { _id: req.params.id, createdBy: req.user._id },
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
    const meeting = await Meeting.findOneAndUpdate(
      { _id: req.params.id, createdBy: req.user._id },
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
    const meeting = await Meeting.findOneAndDelete({
      _id: req.params.id,
      createdBy: req.user._id
    });

    if (!meeting) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    res.json({ message: "Meeting deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
