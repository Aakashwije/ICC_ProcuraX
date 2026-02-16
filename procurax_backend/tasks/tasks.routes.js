/*
  Task routes: maps HTTP endpoints to controller functions.
  All routes use authMiddleware so only logged-in users can access.
*/
import { Router } from "express";
import authMiddleware from "../auth/auth.middleware.js";
import {
  createTask,
  getTasks,
  getTaskById,
  updateTask,
  archiveTask,
  restoreTask,
  deleteTask,
} from "./tasks.controller.js";

/*
  Router instance used by Express.
*/
const router = Router();

/*
  GET /tasks -> list tasks
*/
router.get("/", authMiddleware, getTasks);
/*
  GET /tasks/:id -> fetch a single task
*/
router.get("/:id", authMiddleware, getTaskById);
/*
  POST /tasks -> create a task
*/
router.post("/", authMiddleware, createTask);
/*
  PUT /tasks/:id -> update a task
*/
router.put("/:id", authMiddleware, updateTask);
/*
  PATCH /tasks/:id/archive -> archive task
*/
router.patch("/:id/archive", authMiddleware, archiveTask);
/*
  PATCH /tasks/:id/restore -> restore task
*/
router.patch("/:id/restore", authMiddleware, restoreTask);
/*
  DELETE /tasks/:id -> delete task
*/
router.delete("/:id", authMiddleware, deleteTask);

/*
  Export router so app.js can mount it at /api/tasks.
*/
export default router;
