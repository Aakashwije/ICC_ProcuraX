import { Router } from "express";
import {
	getMeetings,
	createMeeting,
	deleteMeeting,
	updateMeeting,
} from "../controllers/meetingController.js";

const router = Router();

router.get("/", getMeetings);
router.post("/", createMeeting);
router.put("/:id", updateMeeting);
router.put("/update/:id", updateMeeting);
router.delete("/:id", deleteMeeting);

export default router;
