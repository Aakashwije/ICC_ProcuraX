const express = require("express");
const router = express.Router();

const {
  createMeeting,
  getMeetings,
  getMeetingById,
  updateMeeting,
  markMeetingDone,
  deleteMeeting,
} = require("../controllers/meetingController");

// CREATE meeting
router.post("/", createMeeting);

// GET all meetings
router.get("/", getMeetings);

// GET single meeting
router.get("/:id", getMeetingById);

// UPDATE / reschedule meeting
router.put("/:id", updateMeeting);

// MARK meeting as done
router.patch("/:id/done", markMeetingDone);

// DELETE meeting
router.delete("/:id", deleteMeeting);

module.exports = router;
