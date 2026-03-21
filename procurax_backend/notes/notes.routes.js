/*
  Note routes: maps HTTP endpoints to note controller functions.
  All routes are protected by auth middleware.
*/
import { Router } from "express";
import multer from "multer";
import {
  createNote,
  getNotes,
  updateNote,
  deleteNote,
  uploadAttachment,
  deleteAttachment,
} from "./notes.controller.js";
import { authMiddleware } from "../core/middleware/auth.middleware.js";

/*
  Multer memory storage for attachment uploads (buffer → Cloudinary).
*/
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB limit
});

/*
  Router instance for notes module.
*/
const router = Router();

/*
  GET /notes -> list notes
*/
router.get("/", authMiddleware, getNotes);
/*
  POST /notes -> create note
*/
router.post("/", authMiddleware, createNote);
/*
  PUT /notes/:id -> update note
*/
router.put("/:id", authMiddleware, updateNote);
/*
  DELETE /notes/:id -> delete note
*/
router.delete("/:id", authMiddleware, deleteNote);
/*
  POST /notes/:id/attachment -> upload attachment
*/
router.post("/:id/attachment", authMiddleware, upload.single("file"), uploadAttachment);
/*
  DELETE /notes/:id/attachment -> remove attachment
*/
router.delete("/:id/attachment", authMiddleware, deleteAttachment);

/*
  Export router for app.js mounting.
*/
export default router;
