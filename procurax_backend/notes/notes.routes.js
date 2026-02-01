import { Router } from "express";
import {
  createNote,
  getNotes,
  updateNote,
  deleteNote,
} from "./notes.controller.js";
import authMiddleware from "../auth/auth.middleware.js";

const router = Router();

router.get("/", authMiddleware, getNotes);
router.post("/", authMiddleware, createNote);
router.put("/:id", authMiddleware, updateNote);
router.delete("/:id", authMiddleware, deleteNote);

export default router;
