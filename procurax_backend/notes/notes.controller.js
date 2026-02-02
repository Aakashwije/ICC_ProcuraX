import mongoose from "mongoose";
import Note from "./notes.model.js";

const inMemoryStore = new Map();

const getOwnerKey = (req) => req.userId?.toString() ?? "unknown";

const useInMemory = () => mongoose.connection.readyState !== 1;

const normalizeNote = (note) => ({
  id: note._id.toString(),
  title: note.title,
  content: note.content,
  tag: note.tag,
  location: note.location,
  createdAt: note.createdAt,
  lastEdited: note.lastEdited,
  hasAttachment: note.hasAttachment,
});

const requireBodyFields = (req, res) => {
  const { title, content } = req.body || {};
  if (!title || !content) {
    res.status(400).json({ message: "Title and content are required" });
    return null;
  }
  return { title, content };
};

export const createNote = async (req, res) => {
  const body = requireBodyFields(req, res);
  if (!body) return;

  try {
    if (useInMemory()) {
      const now = new Date();
      const note = {
        _id: new mongoose.Types.ObjectId(),
        title: body.title,
        content: body.content,
        tag: req.body.tag ?? "Issue",
        location: req.body.location ?? "Unknown",
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

    const note = await Note.create({
      title: body.title,
      content: body.content,
      tag: req.body.tag ?? "Issue",
      location: req.body.location ?? "Unknown",
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

export const getNotes = async (req, res) => {
  try {
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      return res.json(list.map(normalizeNote));
    }

    const notes = await Note.find({ owner: req.userId }).sort({ createdAt: -1 });
    res.json(notes.map(normalizeNote));
  } catch (err) {
    console.error("Fetch notes failed:", err);
    res.status(500).json({ message: "Failed to fetch notes" });
  }
};

export const updateNote = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid note id" });
  }

  try {
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
        location: req.body.location ?? existing.location,
        hasAttachment: req.body.hasAttachment ?? existing.hasAttachment,
        lastEdited: new Date(),
      };
      list[index] = updated;
      inMemoryStore.set(ownerKey, list);
      return res.json(normalizeNote(updated));
    }

    const update = {
      title: req.body.title,
      content: req.body.content,
      tag: req.body.tag,
      location: req.body.location,
      hasAttachment: req.body.hasAttachment,
      lastEdited: new Date(),
    };

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

export const deleteNote = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid note id" });
  }

  try {
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
