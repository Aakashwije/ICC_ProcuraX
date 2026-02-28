// src/routes/user.routes.js
import express from "express";
import authMiddleware from "../../auth/auth.middleware.js";
import { 
  getAllUsers, 
  addUser, 
  updateUserProfile,
  loginUser,
  getCurrentUser 
} from "../controllers/user.controller.js";

const router = express.Router();

// Public routes (no auth needed)
router.post("/", addUser);           // Register
router.post("/login", loginUser);    // Login

// Protected routes (require JWT)
router.get("/", authMiddleware, getAllUsers);
router.get("/me", authMiddleware, getCurrentUser);
router.put("/:id", authMiddleware, updateUserProfile);

export default router;