/*
  Note routes: maps HTTP endpoints to note controller functions.
  All routes are protected by auth middleware.
*/
import { Router } from "express";
import {
  createNote,
  getNotes,
  updateNote,
  deleteNote,
} from "./notes.controller.js";
import authMiddleware from "../auth/auth.middleware.js";

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
  Export router for app.js mounting.
*/
export default router;
