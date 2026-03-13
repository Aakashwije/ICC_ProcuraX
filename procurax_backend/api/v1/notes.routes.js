/**
 * Notes Routes v1
 * 
 * RESTful API routes for note management with validation.
 */

import { Router } from "express";
import {
  authMiddleware,
  validateBody,
  validateObjectId,
  noteSchemas,
  asyncHandler,
  NoteService,
} from "../../core/index.js";

const router = Router();

// All routes require authentication
router.use(authMiddleware);

/**
 * GET /api/v1/notes
 * Get all notes for the authenticated user
 */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { tag } = req.query;
    const result = await NoteService.getNotes(req.userId, { tag });
    res.json({ success: true, ...result });
  })
);

/**
 * GET /api/v1/notes/tags
 * Get all unique tags for the authenticated user
 */
router.get(
  "/tags",
  asyncHandler(async (req, res) => {
    const tags = await NoteService.getUserTags(req.userId);
    res.json({ success: true, tags });
  })
);

/**
 * GET /api/v1/notes/:id
 * Get a specific note by ID
 */
router.get(
  "/:id",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    const note = await NoteService.getNoteById(req.params.id, req.userId);
    res.json({ success: true, note });
  })
);

/**
 * POST /api/v1/notes
 * Create a new note
 */
router.post(
  "/",
  validateBody(noteSchemas.create),
  asyncHandler(async (req, res) => {
    const note = await NoteService.createNote(req.validatedBody, req.userId);
    res.status(201).json({ success: true, note });
  })
);

/**
 * PUT /api/v1/notes/:id
 * Update a note
 */
router.put(
  "/:id",
  validateObjectId("id"),
  validateBody(noteSchemas.update),
  asyncHandler(async (req, res) => {
    const note = await NoteService.updateNote(
      req.params.id,
      req.userId,
      req.validatedBody
    );
    res.json({ success: true, note });
  })
);

/**
 * DELETE /api/v1/notes/:id
 * Delete a note
 */
router.delete(
  "/:id",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    await NoteService.deleteNote(req.params.id, req.userId);
    res.json({ success: true });
  })
);

export default router;
