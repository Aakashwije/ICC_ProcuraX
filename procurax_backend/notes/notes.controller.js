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
import Note from "./notes.model.js";
import { uploadToCloudinary, deleteFromCloudinary } from "../config/cloudinary.js";

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

/**
 * POST /api/notes/:id/attachment — Upload attachment to a note
 */
export const uploadAttachment = asyncHandler(async (req, res) => {
  const note = await Note.findOne({ _id: req.params.id, owner: req.userId });
  if (!note) return res.status(404).json({ error: "Note not found" });

  if (!req.file) return res.status(400).json({ error: "No file provided" });

  // If note already has an attachment, delete the old one from Cloudinary
  if (note.attachmentPublicId) {
    try {
      await deleteFromCloudinary(note.attachmentPublicId, "raw");
    } catch (err) {
      logger.warn("Failed to delete old attachment from Cloudinary", { err: err.message });
    }
  }

  // Upload to Cloudinary using the buffer from multer memory storage
  const b64 = req.file.buffer.toString("base64");
  const dataUri = `data:${req.file.mimetype};base64,${b64}`;

  const result = await uploadToCloudinary(dataUri, {
    resource_type: "auto",
    folder: `procurax/notes/${req.userId}`,
    public_id: `note_${req.params.id}_${Date.now()}`,
  });

  // Update the note with attachment info
  note.hasAttachment = true;
  note.attachmentUrl = result.secure_url;
  note.attachmentPublicId = result.public_id;
  note.attachmentName = req.file.originalname || "attachment";
  note.lastEdited = new Date();
  await note.save();

  logger.info("Attachment uploaded to note", { noteId: req.params.id, userId: req.userId });

  res.json({
    success: true,
    attachmentUrl: result.secure_url,
    attachmentName: note.attachmentName,
  });
});

/**
 * DELETE /api/notes/:id/attachment — Remove attachment from a note
 */
export const deleteAttachment = asyncHandler(async (req, res) => {
  const note = await Note.findOne({ _id: req.params.id, owner: req.userId });
  if (!note) return res.status(404).json({ error: "Note not found" });

  if (note.attachmentPublicId) {
    try {
      await deleteFromCloudinary(note.attachmentPublicId, "raw");
    } catch (err) {
      logger.warn("Failed to delete attachment from Cloudinary", { err: err.message });
    }
  }

  note.hasAttachment = false;
  note.attachmentUrl = "";
  note.attachmentPublicId = "";
  note.attachmentName = "";
  note.lastEdited = new Date();
  await note.save();

  logger.info("Attachment deleted from note", { noteId: req.params.id, userId: req.userId });

  res.json({ success: true });
});

