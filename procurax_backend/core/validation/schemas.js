/**
 * Joi Validation Schemas
 * 
 * Centralized validation schemas for all API endpoints.
 */

import Joi from "joi";

// ============ Common Schemas ============

export const objectIdSchema = Joi.string()
  .regex(/^[0-9a-fA-F]{24}$/)
  .message("Invalid ID format");

export const paginationSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  sortBy: Joi.string().default("createdAt"),
  sortOrder: Joi.string().valid("asc", "desc").default("desc"),
});

// ============ Auth Schemas ============

export const authSchemas = {
  register: Joi.object({
    email: Joi.string().email().required().trim().lowercase()
      .messages({
        "string.email": "Please provide a valid email address",
        "any.required": "Email is required",
      }),
    password: Joi.string().min(6).required()
      .messages({
        "string.min": "Password must be at least 6 characters",
        "any.required": "Password is required",
      }),
    name: Joi.string().trim().min(2).max(100).optional(),
  }),

  login: Joi.object({
    email: Joi.string().email().required().trim().lowercase(),
    password: Joi.string().required(),
  }),

  forgotPassword: Joi.object({
    email: Joi.string().email().required().trim().lowercase(),
  }),

  verifyOTP: Joi.object({
    email: Joi.string().email().required().trim().lowercase(),
    otp: Joi.string().length(6).required()
      .messages({
        "string.length": "OTP must be 6 digits",
      }),
  }),

  resetPassword: Joi.object({
    email: Joi.string().email().required().trim().lowercase(),
    otp: Joi.string().length(6).required(),
    newPassword: Joi.string()
      .min(8)
      .regex(/[A-Z]/, "uppercase")
      .regex(/[a-z]/, "lowercase")
      .regex(/[0-9]/, "number")
      .regex(/[!@#$%^&*(),.?":{}|<>]/, "special character")
      .required()
      .messages({
        "string.min": "Password must be at least 8 characters",
        "string.pattern.name": "Password must contain {#name}",
      }),
  }),
};

// ============ Task Schemas ============

export const taskSchemas = {
  create: Joi.object({
    title: Joi.string().trim().min(1).max(200).required()
      .messages({
        "string.empty": "Title is required",
        "any.required": "Title is required",
      }),
    description: Joi.string().trim().max(2000).allow("").default(""),
    status: Joi.string()
      .valid("todo", "in_progress", "blocked", "done")
      .default("todo"),
    priority: Joi.string()
      .valid("low", "medium", "high", "critical")
      .default("medium"),
    dueDate: Joi.date().iso().allow(null).optional(),
    assignee: Joi.string().trim().max(100).allow("").default(""),
    tags: Joi.array().items(Joi.string().trim().max(50)).max(10).default([]),
    isArchived: Joi.boolean().default(false),
  }),

  update: Joi.object({
    title: Joi.string().trim().min(1).max(200),
    description: Joi.string().trim().max(2000).allow(""),
    status: Joi.string().valid("todo", "in_progress", "blocked", "done"),
    priority: Joi.string().valid("low", "medium", "high", "critical"),
    dueDate: Joi.date().iso().allow(null),
    assignee: Joi.string().trim().max(100).allow(""),
    tags: Joi.array().items(Joi.string().trim().max(50)).max(10),
    isArchived: Joi.boolean(),
  }).min(1).messages({
    "object.min": "At least one field must be provided for update",
  }),

  query: Joi.object({
    archived: Joi.boolean().default(false),
    status: Joi.string().valid("todo", "in_progress", "blocked", "done"),
    priority: Joi.string().valid("low", "medium", "high", "critical"),
    ...paginationSchema.describe().keys,
  }),
};

// ============ Note Schemas ============

export const noteSchemas = {
  create: Joi.object({
    title: Joi.string().trim().min(1).max(200).required()
      .messages({
        "string.empty": "Title is required",
        "any.required": "Title is required",
      }),
    content: Joi.string().trim().min(1).max(10000).required()
      .messages({
        "string.empty": "Content is required",
        "any.required": "Content is required",
      }),
    tag: Joi.string().trim().max(50).default("Issue"),
    hasAttachment: Joi.boolean().default(false),
  }),

  update: Joi.object({
    title: Joi.string().trim().min(1).max(200),
    content: Joi.string().trim().min(1).max(10000),
    tag: Joi.string().trim().max(50),
    hasAttachment: Joi.boolean(),
  }).min(1),
};

// ============ Meeting Schemas ============

export const meetingSchemas = {
  create: Joi.object({
    title: Joi.string().trim().min(1).max(200).required()
      .messages({
        "string.empty": "Title is required",
        "any.required": "Title is required",
      }),
    description: Joi.string().trim().max(2000).allow("").optional(),
    location: Joi.string().trim().max(200).allow("").optional(),
    startTime: Joi.date().iso().required()
      .messages({
        "any.required": "Start time is required",
      }),
    endTime: Joi.date().iso().greater(Joi.ref("startTime")).required()
      .messages({
        "any.required": "End time is required",
        "date.greater": "End time must be after start time",
      }),
    priority: Joi.string().valid("low", "medium", "high").default("medium"),
    done: Joi.boolean().default(false),
  }),

  update: Joi.object({
    title: Joi.string().trim().min(1).max(200),
    description: Joi.string().trim().max(2000).allow(""),
    location: Joi.string().trim().max(200).allow(""),
    startTime: Joi.date().iso(),
    endTime: Joi.date().iso(),
    priority: Joi.string().valid("low", "medium", "high"),
    done: Joi.boolean(),
  }).min(1),
};

// ============ Project Schemas (Admin) ============

export const projectSchemas = {
  create: Joi.object({
    name: Joi.string().trim().min(1).max(200).required(),
    sheetUrl: Joi.string().uri().required()
      .messages({
        "string.uri": "Please provide a valid Google Sheets URL",
      }),
  }),

  update: Joi.object({
    name: Joi.string().trim().min(1).max(200),
    sheetUrl: Joi.string().uri(),
    status: Joi.string().valid("Active", "Inactive", "Completed"),
  }).min(1),

  assignManager: Joi.object({
    projectId: objectIdSchema.required(),
    managerId: objectIdSchema.allow(null).optional(),
  }),
};

// ============ User Schemas (Admin) ============

export const userSchemas = {
  update: Joi.object({
    name: Joi.string().trim().min(2).max(100),
    email: Joi.string().email().trim().lowercase(),
    phone: Joi.string().trim().max(20).allow(""),
    isApproved: Joi.boolean(),
    isActive: Joi.boolean(),
  }).min(1),

  assignSheetUrl: Joi.object({
    googleSheetUrl: Joi.string().uri().allow(null, ""),
  }),
};

// ============ Notification Schemas ============

export const notificationSchemas = {
  create: Joi.object({
    title: Joi.string().trim().min(1).max(200).required(),
    message: Joi.string().trim().min(1).max(1000).required(),
    type: Joi.string()
      .valid("projects", "tasks", "meetings", "system", "alerts")
      .default("system"),
    priority: Joi.string().valid("low", "medium", "high").default("medium"),
  }),

  markRead: Joi.object({
    notificationIds: Joi.array().items(objectIdSchema).min(1).required(),
  }),
};

export default {
  auth: authSchemas,
  task: taskSchemas,
  note: noteSchemas,
  meeting: meetingSchemas,
  project: projectSchemas,
  user: userSchemas,
  notification: notificationSchemas,
};
