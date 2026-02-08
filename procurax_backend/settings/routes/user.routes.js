// src/routes/user.routes.js - SIMPLIFIED
import express from "express";
import { 
  getAllUsers, 
  addUser, 
  updateUserProfile,
  loginUser,
  getCurrentUser 
} from "../controllers/user.controller.js";
// NO authMiddleware!

const router = express.Router();

// Public routes only
router.post("/", addUser);              // Register
router.post("/login", loginUser);       // Login (optional)
router.get("/", getAllUsers);           // Get all users

// If you need these, keep them simple
// router.get("/me", getCurrentUser);    // Remove or modify
// router.put("/:id", updateUserProfile); // Remove or modify

export default router;