/*
  Tasks controller: handles CRUD logic for tasks.
  If MongoDB is down, it falls back to an in-memory store.
*/
import mongoose from "mongoose";
import Task from "./tasks.model.js";

/*
  In-memory fallback store, keyed by owner.
  This allows basic CRUD even if DB is disconnected.
*/
const inMemoryStore = new Map();

/*
  Get a stable key for the current user.
  If no userId, use "unknown" so we still have a key.
*/
const getOwnerKey = (req) => req.userId?.toString() ?? "unknown";

/*
  If Mongo connection is not "connected", use the in-memory store.
*/
const useInMemory = () => mongoose.connection.readyState !== 1;

/*
  Normalize task model into the shape the frontend expects.
*/
const normalizeTask = (task) => ({
  id: task._id.toString(),
  title: task.title,
  description: task.description,
  status: task.status,
  priority: task.priority,
  dueDate: task.dueDate,
  assignee: task.assignee,
  tags: task.tags,
  isArchived: task.isArchived,
  createdAt: task.createdAt,
  updatedAt: task.updatedAt ?? task.updatedAt,
});

/*
  Validate required fields for create requests.
  Returns null if validation fails (response already sent).
*/
const requireTitle = (req, res) => {
  const { title } = req.body || {};
  if (!title) {
    res.status(400).json({ message: "Title is required" });
    return null;
  }
  return { title };
};

/*
  Build the task payload using request data, with defaults.
  We reuse this in create + update to keep logic consistent.
*/
const buildTaskPayload = (req, base = {}) => ({
  ...base,
  title: req.body.title ?? base.title,
  description: req.body.description ?? base.description ?? "",
  status: req.body.status ?? base.status ?? "todo",
  priority: req.body.priority ?? base.priority ?? "medium",
  dueDate: req.body.dueDate ? new Date(req.body.dueDate) : base.dueDate ?? null,
  assignee: req.body.assignee ?? base.assignee ?? "",
  tags: Array.isArray(req.body.tags) ? req.body.tags : base.tags ?? [],
  isArchived: typeof req.body.isArchived === "boolean" ? req.body.isArchived : base.isArchived ?? false,
});

/*
  Create a new task.
  Uses MongoDB if connected, otherwise uses in-memory store.
*/
export const createTask = async (req, res) => {
  const body = requireTitle(req, res);
  if (!body) return;

  try {
    /*
      In-memory mode: build a task object and store it locally.
    */
    if (useInMemory()) {
      const now = new Date();
      const task = {
        _id: new mongoose.Types.ObjectId(),
        ...buildTaskPayload(req, { title: body.title }),
        owner: req.userId,
        createdAt: now,
        updatedAt: now,
      };
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      list.unshift(task);
      inMemoryStore.set(ownerKey, list);
      return res.status(201).json(normalizeTask(task));
    }

    /*
      DB mode: write task to MongoDB.
    */
    const task = await Task.create({
      ...buildTaskPayload(req, { title: body.title }),
      owner: req.userId,
    });

    res.status(201).json(normalizeTask(task));
  } catch (err) {
    console.error("Create task failed:", err);
    res.status(500).json({ message: "Failed to create task" });
  }
};

/*
  Get tasks for current user.
  Supports archived filtering using query param ?archived=true.
*/
export const getTasks = async (req, res) => {
  const archivedOnly = req.query.archived === "true";
  try {
    /*
      In-memory mode: filter tasks locally by archived state.
    */
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      const filtered = list.filter((item) =>
        archivedOnly ? item.isArchived : !item.isArchived
      );
      return res.json(filtered.map(normalizeTask));
    }

    /*
      DB mode: query tasks by owner and archived state.
    */
    const tasks = await Task.find({
      owner: req.userId,
      isArchived: archivedOnly ? true : false,
    }).sort({ createdAt: -1 });
    res.json(tasks.map(normalizeTask));
  } catch (err) {
    console.error("Fetch tasks failed:", err);
    res.status(500).json({ message: "Failed to fetch tasks" });
  }
};

/*
  Get a single task by id for the current user.
*/
export const getTaskById = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid task id" });
  }

  try {
    /*
      In-memory mode: find the task in the list.
    */
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      const task = list.find((item) => item._id.toString() === req.params.id);
      if (!task) return res.status(404).json({ message: "Task not found" });
      return res.json(normalizeTask(task));
    }

    /*
      DB mode: find by id + owner.
    */
    const task = await Task.findOne({ _id: req.params.id, owner: req.userId });
    if (!task) {
      return res.status(404).json({ message: "Task not found" });
    }

    res.json(normalizeTask(task));
  } catch (err) {
    console.error("Fetch task failed:", err);
    res.status(500).json({ message: "Failed to fetch task" });
  }
};

/*
  Update a task by id.
*/
export const updateTask = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid task id" });
  }

  try {
    /*
      In-memory mode: merge new fields into existing task.
    */
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      const index = list.findIndex((item) => item._id.toString() === req.params.id);
      if (index < 0) {
        return res.status(404).json({ message: "Task not found" });
      }
      const existing = list[index];
      const updated = {
        ...existing,
        ...buildTaskPayload(req, existing),
        updatedAt: new Date(),
      };
      list[index] = updated;
      inMemoryStore.set(ownerKey, list);
      return res.json(normalizeTask(updated));
    }

    /*
      DB mode: update and return the latest doc.
    */
    const task = await Task.findOneAndUpdate(
      { _id: req.params.id, owner: req.userId },
      buildTaskPayload(req),
      { new: true }
    );

    if (!task) {
      return res.status(404).json({ message: "Task not found" });
    }

    res.json(normalizeTask(task));
  } catch (err) {
    console.error("Update task failed:", err);
    res.status(500).json({ message: "Failed to update task" });
  }
};

/*
  Archive a task (soft delete) by setting isArchived=true.
*/
export const archiveTask = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid task id" });
  }

  try {
    /*
      In-memory mode: toggle isArchived flag.
    */
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      const index = list.findIndex((item) => item._id.toString() === req.params.id);
      if (index < 0) {
        return res.status(404).json({ message: "Task not found" });
      }
      const existing = list[index];
      const updated = {
        ...existing,
        isArchived: true,
        updatedAt: new Date(),
      };
      list[index] = updated;
      inMemoryStore.set(ownerKey, list);
      return res.json(normalizeTask(updated));
    }

    /*
      DB mode: set isArchived to true.
    */
    const task = await Task.findOneAndUpdate(
      { _id: req.params.id, owner: req.userId },
      { isArchived: true },
      { new: true }
    );

    if (!task) {
      return res.status(404).json({ message: "Task not found" });
    }

    res.json(normalizeTask(task));
  } catch (err) {
    console.error("Archive task failed:", err);
    res.status(500).json({ message: "Failed to archive task" });
  }
};

/*
  Restore a task by setting isArchived=false.
*/
export const restoreTask = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid task id" });
  }

  try {
    /*
      In-memory mode: toggle isArchived back to false.
    */
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      const index = list.findIndex((item) => item._id.toString() === req.params.id);
      if (index < 0) {
        return res.status(404).json({ message: "Task not found" });
      }
      const existing = list[index];
      const updated = {
        ...existing,
        isArchived: false,
        updatedAt: new Date(),
      };
      list[index] = updated;
      inMemoryStore.set(ownerKey, list);
      return res.json(normalizeTask(updated));
    }

    /*
      DB mode: set isArchived to false.
    */
    const task = await Task.findOneAndUpdate(
      { _id: req.params.id, owner: req.userId },
      { isArchived: false },
      { new: true }
    );

    if (!task) {
      return res.status(404).json({ message: "Task not found" });
    }

    res.json(normalizeTask(task));
  } catch (err) {
    console.error("Restore task failed:", err);
    res.status(500).json({ message: "Failed to restore task" });
  }
};

/*
  Delete a task permanently.
*/
export const deleteTask = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid task id" });
  }

  try {
    /*
      In-memory mode: remove task from list.
    */
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      const index = list.findIndex((item) => item._id.toString() === req.params.id);
      if (index < 0) {
        return res.status(404).json({ message: "Task not found" });
      }
      list.splice(index, 1);
      inMemoryStore.set(ownerKey, list);
      return res.json({ success: true });
    }

    const task = await Task.findOneAndDelete({ _id: req.params.id, owner: req.userId });
    if (!task) {
      return res.status(404).json({ message: "Task not found" });
    }
    res.json({ success: true });
  } catch (err) {
    console.error("Delete task failed:", err);
    res.status(500).json({ message: "Failed to delete task" });
  }
};
