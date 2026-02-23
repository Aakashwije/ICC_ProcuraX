import { Router } from "express";
import {
  createMeeting,
  getMeetings,
  getMeetingById,
  updateMeeting,
  markMeetingDone,
  deleteMeeting,
} from "../controllers/meetingController.js";

const router = Router();

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

export default router;
