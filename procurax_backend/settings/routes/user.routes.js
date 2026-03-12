// settings/routes/user.routes.js
import express from "express";
import path from 'path';
import authMiddleware, { generateToken } from "../../auth/auth.middleware.js";  // Added generateToken
import User from '../../models/User.js';
import Setting from '../models/setting.js';

const router = express.Router();

// Public routes (no auth needed)
router.post("/", async (req, res) => {
  try {
    const { email, password, firstName, lastName } = req.body;
    
    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Email already registered'
      });
    }
    
    // Create user
    const user = new User({
      firstName,
      lastName,
      email,
      password,
      name: `${firstName || ''} ${lastName || ''}`.trim()
    });
    
    await user.save();
    
    // Generate token - NOW WORKS because we imported it
    const token = generateToken(user._id);
    
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        id: user._id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email
      },
      token
    });
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    // Generate token - NOW WORKS because we imported it
    const token = generateToken(user._id);
    
    res.json({
      success: true,
      message: 'Login successful',
      data: {
        id: user._id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email
      },
      token
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Protected routes
router.get("/me", authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('-password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const userObj = user.toObject();
    // Ensure front-end receives firstName/lastName even if only 'name' exists
    if (!userObj.firstName || !userObj.lastName) {
      const parts = (userObj.name || '').split(' ');
      userObj.firstName = userObj.firstName || parts[0] || '';
      userObj.lastName = userObj.lastName || parts.slice(1).join(' ') || '';
    }

    // Build a full URL for profile image so frontend can display it after reload
    if (userObj.profileImage) {
      const baseUrl = `${req.protocol}://${req.get('host')}`;
      const relativePath = userObj.profileImage.split(path.sep).join('/');
      userObj.profileImageUrl = `${baseUrl}/${relativePath}`;
    }

    res.json({ success: true, data: userObj });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PROFILE UPDATE ENDPOINT - WORKS WITH AUTO-SAVE
router.put("/profile", authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const updateData = { ...req.body };

    console.log('Updating profile for user:', userId);
    console.log('Update data:', updateData);

    // Remove password if present
    if (updateData.password) {
      delete updateData.password;
    }

    // Keep full 'name' in sync with first/last name
    const firstName = updateData.firstName;
    const lastName = updateData.lastName;
    if (firstName !== undefined || lastName !== undefined) {
      updateData.name = `${firstName ?? ''} ${lastName ?? ''}`.trim();
    }

    const user = await User.findByIdAndUpdate(
      userId,
      { ...updateData, updatedAt: new Date() },
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    console.log('Profile updated for:', user.email);

    const userObj = user.toObject();
    if (!userObj.firstName || !userObj.lastName) {
      const parts = (userObj.name || '').split(' ');
      userObj.firstName = userObj.firstName || parts[0] || '';
      userObj.lastName = userObj.lastName || parts.slice(1).join(' ') || '';
    }

    // Build a full URL for profile image so frontend can display it after reload
    if (userObj.profileImage) {
      const baseUrl = `${req.protocol}://${req.get('host')}`;
      const relativePath = userObj.profileImage.split(path.sep).join('/');
      userObj.profileImageUrl = `${baseUrl}/${relativePath}`;
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: userObj
    });
  } catch (err) {
    console.error('Profile update error:', err);
    res.status(400).json({ success: false, error: err.message });
  }
});

// Update user by ID (comes AFTER /profile)
router.put("/:id", authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const user = await User.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    ).select('-password');
    
    res.json({ success: true, data: user });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

export default router;