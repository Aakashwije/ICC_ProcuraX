/**
 * Task Service Unit Tests
 *
 * Tests the TaskService business logic layer in isolation.
 * All database calls are mocked to focus on logic, not I/O.
 */

import { jest, describe, it, expect, beforeEach } from "@jest/globals";
import { AppError } from "../../core/errors/AppError.js";

/* ------------------------------------------------------------------ */
/*  Mock Mongoose model                                                */
/* ------------------------------------------------------------------ */
const mockSave = jest.fn();

const MockTaskConstructor = jest.fn().mockImplementation(function (data) {
  Object.assign(this, data);
  this._id = { toString: () => "task_001" };
  this.createdAt = new Date("2024-01-01");
  this.updatedAt = new Date("2024-01-01");
  this.save = mockSave.mockResolvedValue(this);
});

MockTaskConstructor.find = jest.fn();
MockTaskConstructor.findOne = jest.fn();
MockTaskConstructor.findOneAndUpdate = jest.fn();
MockTaskConstructor.findOneAndDelete = jest.fn();
MockTaskConstructor.countDocuments = jest.fn();
MockTaskConstructor.aggregate = jest.fn();

jest.unstable_mockModule("../../tasks/tasks.model.js", () => ({
  default: MockTaskConstructor,
}));

// Dynamic import AFTER mock registration
const { default: TaskService } = await import("../../core/services/task.service.js");
const Task = MockTaskConstructor;

/* ------------------------------------------------------------------ */
/*  Constants                                                          */
/* ------------------------------------------------------------------ */
const USER_ID = "507f1f77bcf86cd799439011";

const MOCK_TASK = {
  _id: { toString: () => "task_001" },
  title: "Write unit tests",
  description: "Cover service layer with Jest",
  status: "todo",
  priority: "high",
  dueDate: null,
  assignee: "",
  tags: ["testing"],
  isArchived: false,
  createdAt: new Date("2024-01-01"),
  updatedAt: new Date("2024-01-01"),
};

/* ------------------------------------------------------------------ */
/*  Test Suites                                                        */
/* ------------------------------------------------------------------ */
describe("TaskService", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  /* -------------------- createTask -------------------- */
  describe("createTask", () => {
    it("should create a task and return normalised output", async () => {
      mockSave.mockResolvedValueOnce(undefined);

      const result = await TaskService.createTask(
        { title: "Test", priority: "high" },
        USER_ID
      );

      expect(result).toHaveProperty("id", "task_001");
      expect(result).toHaveProperty("title", "Test");
      expect(result).toHaveProperty("priority", "high");
    });

    it("should propagate database save errors", async () => {
      mockSave.mockRejectedValueOnce(new Error("DB write failed"));

      await expect(
        TaskService.createTask({ title: "Fail" }, USER_ID)
      ).rejects.toThrow("DB write failed");
    });
  });

  /* -------------------- getTasks -------------------- */
  describe("getTasks", () => {
    it("should return paginated tasks for a user", async () => {
      const chainable = {
        sort: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue([MOCK_TASK]),
      };
      Task.find.mockReturnValue(chainable);
      Task.countDocuments.mockResolvedValue(1);

      const result = await TaskService.getTasks(USER_ID);

      expect(Task.find).toHaveBeenCalledWith(
        expect.objectContaining({ owner: USER_ID, isArchived: false })
      );
      expect(result.tasks).toHaveLength(1);
      expect(result.pagination).toEqual({
        page: 1,
        limit: 50,
        total: 1,
        pages: 1,
      });
    });

    it("should filter by status and priority when provided", async () => {
      const chainable = {
        sort: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue([]),
      };
      Task.find.mockReturnValue(chainable);
      Task.countDocuments.mockResolvedValue(0);

      await TaskService.getTasks(USER_ID, {
        status: "done",
        priority: "low",
        page: 2,
        limit: 10,
      });

      expect(Task.find).toHaveBeenCalledWith(
        expect.objectContaining({
          owner: USER_ID,
          status: "done",
          priority: "low",
        })
      );
      expect(chainable.skip).toHaveBeenCalledWith(10); // (page-1)*limit
      expect(chainable.limit).toHaveBeenCalledWith(10);
    });
  });

  /* -------------------- getTaskById -------------------- */
  describe("getTaskById", () => {
    it("should return a single task owned by the user", async () => {
      Task.findOne.mockResolvedValue(MOCK_TASK);

      const result = await TaskService.getTaskById("task_001", USER_ID);

      expect(result.id).toBe("task_001");
      expect(Task.findOne).toHaveBeenCalledWith({
        _id: "task_001",
        owner: USER_ID,
      });
    });

    it("should throw NotFound when task does not exist", async () => {
      Task.findOne.mockResolvedValue(null);

      await expect(
        TaskService.getTaskById("missing_id", USER_ID)
      ).rejects.toThrow(AppError);
    });
  });

  /* -------------------- updateTask -------------------- */
  describe("updateTask", () => {
    it("should update and return the task", async () => {
      const updated = { ...MOCK_TASK, title: "Updated" };
      Task.findOneAndUpdate.mockResolvedValue(updated);

      const result = await TaskService.updateTask("task_001", USER_ID, {
        title: "Updated",
      });

      expect(result.title).toBe("Updated");
      expect(Task.findOneAndUpdate).toHaveBeenCalledWith(
        { _id: "task_001", owner: USER_ID },
        { $set: { title: "Updated" } },
        { new: true, runValidators: true }
      );
    });

    it("should throw NotFound when task does not exist", async () => {
      Task.findOneAndUpdate.mockResolvedValue(null);

      await expect(
        TaskService.updateTask("bad_id", USER_ID, { title: "X" })
      ).rejects.toThrow(AppError);
    });
  });

  /* -------------------- archiveTask / restoreTask -------------------- */
  describe("archiveTask", () => {
    it("should set isArchived to true", async () => {
      Task.findOneAndUpdate.mockResolvedValue({
        ...MOCK_TASK,
        isArchived: true,
      });

      const result = await TaskService.archiveTask("task_001", USER_ID);
      expect(result.isArchived).toBe(true);
    });

    it("should throw NotFound for non-existent task", async () => {
      Task.findOneAndUpdate.mockResolvedValue(null);
      await expect(
        TaskService.archiveTask("bad", USER_ID)
      ).rejects.toThrow(AppError);
    });
  });

  describe("restoreTask", () => {
    it("should set isArchived to false", async () => {
      Task.findOneAndUpdate.mockResolvedValue({
        ...MOCK_TASK,
        isArchived: false,
      });

      const result = await TaskService.restoreTask("task_001", USER_ID);
      expect(result.isArchived).toBe(false);
    });
  });

  /* -------------------- deleteTask -------------------- */
  describe("deleteTask", () => {
    it("should delete and return success", async () => {
      Task.findOneAndDelete.mockResolvedValue(MOCK_TASK);

      const result = await TaskService.deleteTask("task_001", USER_ID);
      expect(result).toEqual({ success: true });
    });

    it("should throw NotFound when task missing", async () => {
      Task.findOneAndDelete.mockResolvedValue(null);

      await expect(
        TaskService.deleteTask("bad", USER_ID)
      ).rejects.toThrow(AppError);
    });
  });

  /* -------------------- getTaskStats -------------------- */
  describe("getTaskStats", () => {
    it("should aggregate task counts by status", async () => {
      Task.aggregate.mockResolvedValue([
        { _id: "todo", count: 5 },
        { _id: "done", count: 3 },
        { _id: "in_progress", count: 2 },
      ]);

      const stats = await TaskService.getTaskStats(USER_ID);

      expect(stats.todo).toBe(5);
      expect(stats.done).toBe(3);
      expect(stats.in_progress).toBe(2);
      expect(stats.total).toBe(10);
      expect(stats.blocked).toBe(0); // not in aggregate result
    });

    it("should return all zeros when no tasks exist", async () => {
      Task.aggregate.mockResolvedValue([]);

      const stats = await TaskService.getTaskStats(USER_ID);
      expect(stats.total).toBe(0);
    });
  });

  /* -------------------- normalizeTask -------------------- */
  describe("normalizeTask", () => {
    it("should return a plain object with id instead of _id", () => {
      const result = TaskService.normalizeTask(MOCK_TASK);

      expect(result.id).toBe("task_001");
      expect(result._id).toBeUndefined();
      expect(result).toHaveProperty("title");
      expect(result).toHaveProperty("status");
      expect(result).toHaveProperty("priority");
      expect(result).toHaveProperty("tags");
      expect(result).toHaveProperty("isArchived");
    });
  });
});

/* ================================================================== */
/*  AppError                                                           */
/* ================================================================== */
describe("AppError", () => {
  it("should create a 400 bad-request error", () => {
    const err = AppError.badRequest("Invalid input");
    expect(err.statusCode).toBe(400);
    expect(err.errorCode).toBe("BAD_REQUEST");
    expect(err.message).toBe("Invalid input");
    expect(err.isOperational).toBe(true);
  });

  it("should create a 401 unauthorised error", () => {
    const err = AppError.unauthorized("Not logged in");
    expect(err.statusCode).toBe(401);
    expect(err.errorCode).toBe("UNAUTHORIZED");
  });

  it("should create a 403 forbidden error", () => {
    const err = AppError.forbidden("Admin only");
    expect(err.statusCode).toBe(403);
    expect(err.errorCode).toBe("FORBIDDEN");
  });

  it("should create a 404 not-found error with entity name", () => {
    const err = AppError.notFound("Task");
    expect(err.statusCode).toBe(404);
    expect(err.message).toBe("Task not found");
  });

  it("should create a 409 conflict error", () => {
    const err = AppError.conflict("Email already registered");
    expect(err.statusCode).toBe(409);
    expect(err.errorCode).toBe("CONFLICT");
  });

  it("should create a 422 validation error with details", () => {
    const details = [{ field: "title", message: "Required" }];
    const err = AppError.validation(details);
    expect(err.statusCode).toBe(422);
    expect(err.details).toEqual(details);
  });

  it("should serialise to JSON correctly", () => {
    const err = AppError.badRequest("oops");
    const json = err.toJSON();
    expect(json.success).toBe(false);
    expect(json.error.code).toBe("BAD_REQUEST");
    expect(json.error.message).toBe("oops");
    expect(json.error.timestamp).toBeDefined();
  });
});
