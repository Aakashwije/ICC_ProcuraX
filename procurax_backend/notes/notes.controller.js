/**
 * Notes Controller (Refactored)
 *
 * Thin controller layer — delegates ALL business logic to NoteService.
 * Controller handles only HTTP request/response concerns.
 *
 * Architecture: Controller → Service → Model (3-tier)
 */

import NoteService from "../core/services/note.service.js";
import NotificationService from "../notifications/notification.service.js";
import { asyncHandler } from "../core/middleware/errorHandler.js";
import logger from "../core/logging/logger.js";

/**
 * POST /api/notes — Create a new note
 */
export const createNote = asyncHandler(async (req, res) => {
  const note = await NoteService.createNote(req.body, req.userId);

  // Fire-and-forget notification
  NotificationService.createNoteNotification(req.userId, {
    noteTitle: note.title,
    noteId: note.id,
    action: "created",
    tag: note.tag,
  }).catch((err) => logger.error("Note notification failed", { err: err.message }));

  res.status(201).json(note);
});

/**
 * GET /api/notes — Get all notes for the authenticated user
 */
export const getNotes = asyncHandler(async (req, res) => {
  const { tag, page, limit } = req.query;

  const result = await NoteService.getNotes(req.userId, {
    tag,
    page: page ? parseInt(page) : undefined,
    limit: limit ? parseInt(limit) : undefined,
  });

  // Return flat array for backward compatibility with frontend
  res.json(result.notes);
});

/**
 * PUT /api/notes/:id — Update a note
 */
export const updateNote = asyncHandler(async (req, res) => {
  const note = await NoteService.updateNote(req.params.id, req.userId, req.body);

  // Fire-and-forget notification
  NotificationService.createNoteNotification(req.userId, {
    noteTitle: note.title,
    noteId: note.id,
    action: "updated",
    tag: note.tag,
  }).catch((err) => logger.error("Note update notification failed", { err: err.message }));

  res.json(note);
});

/**
 * DELETE /api/notes/:id — Delete a note
 */
export const deleteNote = asyncHandler(async (req, res) => {
  await NoteService.deleteNote(req.params.id, req.userId);
  res.json({ success: true });
});

