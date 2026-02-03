import mongoose from "mongoose";
import Task from "./tasks.model.js";

const inMemoryStore = new Map();

const getOwnerKey = (req) => req.userId?.toString() ?? "unknown";

const useInMemory = () => mongoose.connection.readyState !== 1;

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

const requireTitle = (req, res) => {
  const { title } = req.body || {};
  if (!title) {
    res.status(400).json({ message: "Title is required" });
    return null;
  }
  return { title };
};

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

export const createTask = async (req, res) => {
  const body = requireTitle(req, res);
  if (!body) return;

  try {
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

export const getTasks = async (req, res) => {
  try {
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      return res.json(list.map(normalizeTask));
    }

    const tasks = await Task.find({ owner: req.userId, isArchived: false }).sort({ createdAt: -1 });
    res.json(tasks.map(normalizeTask));
  } catch (err) {
    console.error("Fetch tasks failed:", err);
    res.status(500).json({ message: "Failed to fetch tasks" });
  }
};

export const getTaskById = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid task id" });
  }

  try {
    if (useInMemory()) {
      const ownerKey = getOwnerKey(req);
      const list = inMemoryStore.get(ownerKey) ?? [];
      const task = list.find((item) => item._id.toString() === req.params.id);
      if (!task) return res.status(404).json({ message: "Task not found" });
      return res.json(normalizeTask(task));
    }

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

export const updateTask = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid task id" });
  }

  try {
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

export const archiveTask = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid task id" });
  }

  try {
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

export const deleteTask = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: "Invalid task id" });
  }

  try {
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
