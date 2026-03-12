/**
 * Meetings Routes v1
 * 
 * RESTful API routes for meeting management with validation.
 */

import { Router } from "express";
import {
  authMiddleware,
  validateBody,
  validateObjectId,
  meetingSchemas,
  asyncHandler,
  MeetingService,
} from "../../core/index.js";

const router = Router();

// All routes require authentication
router.use(authMiddleware);

/**
 * GET /api/v1/meetings
 * Get all meetings for the authenticated user
 */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { done, startDate, endDate } = req.query;
    const result = await MeetingService.getMeetings(req.userId, {
      done: done === "true" ? true : done === "false" ? false : undefined,
      startDate,
      endDate,
    });
    res.json({ success: true, ...result });
  })
);

/**
 * GET /api/v1/meetings/upcoming
 * Get upcoming meetings for the authenticated user
 */
router.get(
  "/upcoming",
  asyncHandler(async (req, res) => {
    const limit = parseInt(req.query.limit) || 5;
    const meetings = await MeetingService.getUpcomingMeetings(req.userId, limit);
    res.json({ success: true, meetings });
  })
);

/**
 * GET /api/v1/meetings/:id
 * Get a specific meeting by ID
 */
router.get(
  "/:id",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    const meeting = await MeetingService.getMeetingById(req.params.id, req.userId);
    res.json({ success: true, meeting });
  })
);

/**
 * POST /api/v1/meetings
 * Create a new meeting
 */
router.post(
  "/",
  validateBody(meetingSchemas.create),
  asyncHandler(async (req, res) => {
    const meeting = await MeetingService.createMeeting(req.validatedBody, req.userId);
    res.status(201).json({ success: true, meeting });
  })
);

/**
 * PUT /api/v1/meetings/:id
 * Update a meeting
 */
router.put(
  "/:id",
  validateObjectId("id"),
  validateBody(meetingSchemas.update),
  asyncHandler(async (req, res) => {
    const meeting = await MeetingService.updateMeeting(
      req.params.id,
      req.userId,
      req.validatedBody
    );
    res.json({ success: true, meeting });
  })
);

/**
 * PATCH /api/v1/meetings/:id/done
 * Mark meeting as done
 */
router.patch(
  "/:id/done",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    const done = req.body.done !== false;
    const meeting = await MeetingService.markMeetingDone(req.params.id, req.userId, done);
    res.json({ success: true, meeting });
  })
);

/**
 * DELETE /api/v1/meetings/:id
 * Delete a meeting
 */
router.delete(
  "/:id",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    await MeetingService.deleteMeeting(req.params.id, req.userId);
    res.json({ success: true });
  })
);

export default router;
