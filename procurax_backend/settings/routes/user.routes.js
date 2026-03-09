// src/routes/user.routes.js
import express from "express";
import authMiddleware from "../../auth/auth.middleware.js";
import User from '../models/User.js';
import Setting from '../models/setting.js';
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

// ===== PROFILE UPDATE ENDPOINT FOR AUTO-SAVE =====
// Update current user profile using token from auth middleware
router.put("/profile", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId; // Get user ID from auth middleware
    const updateData = req.body;
    
    if (process.env.NODE_ENV !== 'production') {
      console.log('Updating profile for user:', userId);
      console.log('Update data:', updateData);
    }
    
    // Remove password from update data (use separate endpoint for password change)
    if (updateData.password) {
      delete updateData.password;
    }
    
    // Find and update user
    const user = await User.findByIdAndUpdate(
      userId,
      { ...updateData, updatedAt: new Date() },
      { new: true, runValidators: true }
    ).select('-password');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // If theme is updated, also update settings
    if (updateData.theme) {
      await Setting.findOneAndUpdate(
        { userId: userId, key: 'theme' },
        { value: updateData.theme, updatedAt: new Date() },
        { upsert: true }
      );
    }
    
    console.log('Profile updated successfully for user:', user.email);
    
    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: user
    });
  } catch (err) {
    console.error('Profile update error:', err);
    res.status(400).json({
      success: false,
      message: 'Error updating profile',
      error: err.message
    });
  }
});

export default router;