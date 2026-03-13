/**
 * Note Service
 * 
 * Business logic layer for note operations.
 */

import Note from "../../notes/notes.model.js";
import { AppError } from "../errors/AppError.js";
import logger from "../logging/logger.js";

class NoteService {
  /**
   * Create a new note
   */
  async createNote(data, userId) {
    logger.debug("Creating note", { userId, title: data.title });

    const note = new Note({
      ...data,
      owner: userId,
      createdAt: new Date(),
      lastEdited: new Date(),
    });

    await note.save();

    logger.info("Note created", { noteId: note._id, userId });
    return this.normalizeNote(note);
  }

  /**
   * Get all notes for a user
   */
  async getNotes(userId, options = {}) {
    const { tag, page = 1, limit = 50 } = options;

    const query = { owner: userId };
    if (tag) query.tag = tag;

    const notes = await Note.find(query)
      .sort({ lastEdited: -1 })
      .skip((page - 1) * limit)
      .limit(limit);

    const total = await Note.countDocuments(query);

    return {
      notes: notes.map((n) => this.normalizeNote(n)),
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get a single note by ID
   */
  async getNoteById(noteId, userId) {
    const note = await Note.findOne({ _id: noteId, owner: userId });

    if (!note) {
      throw AppError.notFound("Note");
    }

    return this.normalizeNote(note);
  }

  /**
   * Update a note
   */
  async updateNote(noteId, userId, updates) {
    logger.debug("Updating note", { noteId, userId });

    const note = await Note.findOneAndUpdate(
      { _id: noteId, owner: userId },
      {
        $set: {
          ...updates,
          lastEdited: new Date(),
        },
      },
      { new: true, runValidators: true }
    );

    if (!note) {
      throw AppError.notFound("Note");
    }

    logger.info("Note updated", { noteId, userId });
    return this.normalizeNote(note);
  }

  /**
   * Delete a note
   */
  async deleteNote(noteId, userId) {
    const note = await Note.findOneAndDelete({ _id: noteId, owner: userId });

    if (!note) {
      throw AppError.notFound("Note");
    }

    logger.info("Note deleted", { noteId, userId });
    return { success: true };
  }

  /**
   * Get all unique tags for a user
   */
  async getUserTags(userId) {
    const tags = await Note.distinct("tag", { owner: userId });
    return tags;
  }

  /**
   * Normalize note object for API response
   */
  normalizeNote(note) {
    return {
      id: note._id.toString(),
      title: note.title,
      content: note.content,
      tag: note.tag,
      createdAt: note.createdAt,
      lastEdited: note.lastEdited,
      hasAttachment: note.hasAttachment,
    };
  }
}

export default new NoteService();
