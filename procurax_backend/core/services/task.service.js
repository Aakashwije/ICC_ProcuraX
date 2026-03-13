/**
 * Task Service
 * 
 * Business logic layer for task operations.
 * Handles CRUD operations, validation, and caching.
 */

import Task from "../../tasks/tasks.model.js";
import { AppError } from "../errors/AppError.js";
import logger from "../logging/logger.js";

class TaskService {
  /**
   * Create a new task
   */
  async createTask(data, userId) {
    logger.debug("Creating task", { userId, title: data.title });

    const task = new Task({
      ...data,
      owner: userId,
    });

    await task.save();

    logger.info("Task created", { taskId: task._id, userId });
    return this.normalizeTask(task);
  }

  /**
   * Get all tasks for a user
   */
  async getTasks(userId, options = {}) {
    const { archived = false, status, priority, page = 1, limit = 50 } = options;

    const query = {
      owner: userId,
      isArchived: archived,
    };

    if (status) query.status = status;
    if (priority) query.priority = priority;

    const tasks = await Task.find(query)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);

    const total = await Task.countDocuments(query);

    return {
      tasks: tasks.map((t) => this.normalizeTask(t)),
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get a single task by ID
   */
  async getTaskById(taskId, userId) {
    const task = await Task.findOne({ _id: taskId, owner: userId });

    if (!task) {
      throw AppError.notFound("Task");
    }

    return this.normalizeTask(task);
  }

  /**
   * Update a task
   */
  async updateTask(taskId, userId, updates) {
    logger.debug("Updating task", { taskId, userId, updates: Object.keys(updates) });

    const task = await Task.findOneAndUpdate(
      { _id: taskId, owner: userId },
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!task) {
      throw AppError.notFound("Task");
    }

    logger.info("Task updated", { taskId, userId });
    return this.normalizeTask(task);
  }

  /**
   * Archive a task (soft delete)
   */
  async archiveTask(taskId, userId) {
    const task = await Task.findOneAndUpdate(
      { _id: taskId, owner: userId },
      { $set: { isArchived: true } },
      { new: true }
    );

    if (!task) {
      throw AppError.notFound("Task");
    }

    logger.info("Task archived", { taskId, userId });
    return this.normalizeTask(task);
  }

  /**
   * Restore an archived task
   */
  async restoreTask(taskId, userId) {
    const task = await Task.findOneAndUpdate(
      { _id: taskId, owner: userId },
      { $set: { isArchived: false } },
      { new: true }
    );

    if (!task) {
      throw AppError.notFound("Task");
    }

    logger.info("Task restored", { taskId, userId });
    return this.normalizeTask(task);
  }

  /**
   * Delete a task permanently
   */
  async deleteTask(taskId, userId) {
    const task = await Task.findOneAndDelete({ _id: taskId, owner: userId });

    if (!task) {
      throw AppError.notFound("Task");
    }

    logger.info("Task deleted", { taskId, userId });
    return { success: true };
  }

  /**
   * Get task statistics for a user
   */
  async getTaskStats(userId) {
    const stats = await Task.aggregate([
      { $match: { owner: userId, isArchived: false } },
      {
        $group: {
          _id: "$status",
          count: { $sum: 1 },
        },
      },
    ]);

    const result = {
      todo: 0,
      in_progress: 0,
      blocked: 0,
      done: 0,
      total: 0,
    };

    stats.forEach((s) => {
      result[s._id] = s.count;
      result.total += s.count;
    });

    return result;
  }

  /**
   * Normalize task object for API response
   */
  normalizeTask(task) {
    return {
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
      updatedAt: task.updatedAt,
    };
  }
}

export default new TaskService();
