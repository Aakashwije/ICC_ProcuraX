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

const router = Router();

router.get("/", authMiddleware, getTasks);
router.get("/:id", authMiddleware, getTaskById);
router.post("/", authMiddleware, createTask);
router.put("/:id", authMiddleware, updateTask);
router.patch("/:id/archive", authMiddleware, archiveTask);
router.patch("/:id/restore", authMiddleware, restoreTask);
router.delete("/:id", authMiddleware, deleteTask);

export default router;
