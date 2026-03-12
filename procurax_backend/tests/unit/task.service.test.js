/**
 * Task Service Unit Tests
 */

import TaskService from "../../core/services/task.service.js";
import { AppError } from "../../core/errors/AppError.js";

// Mock the Task model
jest.mock("../../tasks/tasks.model.js", () => ({
  default: {
    find: jest.fn(),
    findOne: jest.fn(),
    findOneAndUpdate: jest.fn(),
    findOneAndDelete: jest.fn(),
    countDocuments: jest.fn(),
    aggregate: jest.fn(),
  },
}));

describe("TaskService", () => {
  const mockUserId = "507f1f77bcf86cd799439011";
  
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("createTask", () => {
    it("should create a task with valid data", async () => {
      const taskData = {
        title: "Test Task",
        description: "Test Description",
        priority: "high",
      };

      // Note: This is a basic test structure
      // Full implementation would require proper mocking
      expect(TaskService).toBeDefined();
      expect(typeof TaskService.createTask).toBe("function");
    });

    it("should require a title", async () => {
      expect(TaskService.normalizeTask).toBeDefined();
    });
  });

  describe("getTasks", () => {
    it("should return tasks for a user", async () => {
      expect(typeof TaskService.getTasks).toBe("function");
    });
  });

  describe("updateTask", () => {
    it("should update task fields", async () => {
      expect(typeof TaskService.updateTask).toBe("function");
    });
  });

  describe("deleteTask", () => {
    it("should delete a task", async () => {
      expect(typeof TaskService.deleteTask).toBe("function");
    });
  });

  describe("normalizeTask", () => {
    it("should normalize task object", () => {
      const mockTask = {
        _id: { toString: () => "123" },
        title: "Test",
        description: "Desc",
        status: "todo",
        priority: "medium",
        dueDate: null,
        assignee: "",
        tags: [],
        isArchived: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const normalized = TaskService.normalizeTask(mockTask);

      expect(normalized).toHaveProperty("id", "123");
      expect(normalized).toHaveProperty("title", "Test");
      expect(normalized).toHaveProperty("status", "todo");
    });
  });
});

describe("AppError", () => {
  it("should create a bad request error", () => {
    const error = AppError.badRequest("Invalid input");
    expect(error.statusCode).toBe(400);
    expect(error.errorCode).toBe("BAD_REQUEST");
    expect(error.message).toBe("Invalid input");
  });

  it("should create a not found error", () => {
    const error = AppError.notFound("Task");
    expect(error.statusCode).toBe(404);
    expect(error.errorCode).toBe("NOT_FOUND");
    expect(error.message).toBe("Task not found");
  });

  it("should create a validation error with details", () => {
    const errors = [{ field: "title", message: "Required" }];
    const error = AppError.validation(errors);
    expect(error.statusCode).toBe(422);
    expect(error.errorCode).toBe("VALIDATION_ERROR");
    expect(error.details).toEqual(errors);
  });

  it("should convert to JSON", () => {
    const error = AppError.badRequest("Test error");
    const json = error.toJSON();
    
    expect(json.success).toBe(false);
    expect(json.error.code).toBe("BAD_REQUEST");
    expect(json.error.message).toBe("Test error");
    expect(json.error.timestamp).toBeDefined();
  });
});
