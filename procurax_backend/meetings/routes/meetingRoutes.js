import { Router } from "express";
import authMiddleware from "../../auth/auth.middleware.js";
import {
  createMeeting,
  getMeetings,
  getMeetingById,
  updateMeeting,
  markMeetingDone,
  deleteMeeting,
} from "../controllers/meetingController.js";

const router = Router();

// All routes require a valid JWT — only the owner can CRUD their meetings
router.post("/", authMiddleware, createMeeting);
router.get("/", authMiddleware, getMeetings);
router.get("/:id", authMiddleware, getMeetingById);
router.put("/:id", authMiddleware, updateMeeting);
router.patch("/:id/done", authMiddleware, markMeetingDone);
router.delete("/:id", authMiddleware, deleteMeeting);

export default router;
