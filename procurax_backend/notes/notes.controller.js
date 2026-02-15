/*
  Notes controller: handles CRUD logic for notes.
  Falls back to in-memory store if MongoDB is not connected.
*/
import mongoose from "mongoose";
import Note from "./notes.model.js";

/*
  In-memory fallback store for notes.
*/
const inMemoryStore = new Map();

/*
  Use a stable key for current user.
*/
const getOwnerKey = (req) => req.userId?.toString() ?? "unknown";

/*
  If DB is not connected, use memory instead.
*/
const useInMemory = () => mongoose.connection.readyState !== 1;

/*
  Normalize note into UI-friendly shape.
*/
const normalizeNote = (note) => ({
  id: note._id.toString(),
  title: note.title,
  content: note.content,
  tag: note.tag,
  createdAt: note.createdAt,
  lastEdited: note.lastEdited,
  hasAttachment: note.hasAttachment,
});

/*
  Validate required fields for create.
*/
const requireBodyFields = (req, res) => {
  const { title, content } = req.body || {};
  if (!title || !content) {
    res.status(400).json({ message: "Title and content are required" });
    return null;
  }
  return { title, content };
};

/*
  Create a note.
*/
export const createNote = async (req, res) => {
  const body = requireBodyFields(req, res);
  if (!body) return;

  try {
    /*
      In-memory mode: create and store the note locally.
    */
    if (useInMemory()) {
      const now = new Date();
      const note = {
        _id: new mongoose.Types.ObjectId(),
        title: body.title,
        content: body.content,
        tag: req.body.tag ?? "Issue",
        hasAttachment: Boolean(req.body.hasAttachment),
        createdAt: now,
        lastEdited: now,
      };
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      list.unshift(note);
      inMemoryStore.set(ownerKey, list);
      return res.status(201).json(normalizeNote(note));
    }

    /*
      DB mode: create note in MongoDB.
    */
    const note = await Note.create({
      title: body.title,
      content: body.content,
      tag: req.body.tag ?? "Issue",
      hasAttachment: Boolean(req.body.hasAttachment),
      owner: req.userId,
      lastEdited: new Date(),
    });

    res.status(201).json(normalizeNote(note));
  } catch (err) {
    console.error("Create note failed:", err);
    res.status(500).json({ message: "Failed to create note" });
  }
};

/*
  Get all notes for the current user.
*/
export const getNotes = async (req, res) => {
  try {
    /*
      In-memory mode: return stored notes.
    */
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      return res.json(list.map(normalizeNote));
    }

    /*
      DB mode: query notes by owner.
    */
    const notes = await Note.find({ owner: req.userId }).sort({ createdAt: -1 });
    res.json(notes.map(normalizeNote));
  } catch (err) {
    console.error("Fetch notes failed:", err);
    res.status(500).json({ message: "Failed to fetch notes" });
  }
};

/*
  Update a note by id.
*/
export const updateNote = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid note id" });
  }

  try {
    /*
      In-memory mode: update note in list.
    */
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      const index = list.findIndex(
        (item) => item._id.toString() === req.params.id
      );
      if (index < 0) {
        return res.status(404).json({ message: "Note not found" });
      }
      const existing = list[index];
      const updated = {
        ...existing,
        title: req.body.title ?? existing.title,
        content: req.body.content ?? existing.content,
        tag: req.body.tag ?? existing.tag,
        hasAttachment: req.body.hasAttachment ?? existing.hasAttachment,
        lastEdited: new Date(),
      };
      list[index] = updated;
      inMemoryStore.set(ownerKey, list);
      return res.json(normalizeNote(updated));
    }

    /*
      Build update payload for DB write.
    */
    const update = {
      title: req.body.title,
      content: req.body.content,
      tag: req.body.tag,
      hasAttachment: req.body.hasAttachment,
      lastEdited: new Date(),
    };

    /*
      DB mode: update note and return newest version.
    */
    const note = await Note.findOneAndUpdate(
      { _id: req.params.id, owner: req.userId },
      update,
      { new: true }
    );

    if (!note) {
      return res.status(404).json({ message: "Note not found" });
    }

    res.json(normalizeNote(note));
  } catch (err) {
    console.error("Update note failed:", err);
    res.status(500).json({ message: "Failed to update note" });
  }
};

/*
  Delete a note by id.
*/
export const deleteNote = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid note id" });
  }

  try {
    /*
      In-memory mode: remove note from list.
    */
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      const index = list.findIndex(
        (item) => item._id.toString() === req.params.id
      );
      if (index < 0) {
        return res.status(404).json({ message: "Note not found" });
      }
      list.splice(index, 1);
      inMemoryStore.set(ownerKey, list);
      return res.json({ success: true });
    }

    const note = await Note.findOneAndDelete({
      _id: req.params.id,
      owner: req.userId,
    });
    if (!note) {
      return res.status(404).json({ message: "Note not found" });
    }
    res.json({ success: true });
  } catch (err) {
    console.error("Delete note failed:", err);
    res.status(500).json({ message: "Failed to delete note" });
  }
};
