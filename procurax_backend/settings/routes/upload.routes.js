import express from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { authMiddleware } from  "../../core/middleware/auth.middleware.js";
import User from '../models/User.js';

const router = express.Router();

// Ensure upload directory exists
const uploadDir = 'uploads/profile-images';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, 'profile-' + uniqueSuffix + ext);
  }
});

const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);
  
  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Only image files are allowed (jpeg, jpg, png, gif)'));
  }
};

const upload = multer({ 
  storage: storage,
  limits: { 
    fileSize: 2 * 1024 * 1024 // 2MB limit
  },
  fileFilter: fileFilter
});

// Upload profile image
router.post('/profile-image', 
  authMiddleware, 
  upload.single('profileImage'), 
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No file uploaded'
        });
      }
      
      // Get user
      const user = await User.findById(req.userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }
      
      // Delete old profile image if exists
      if (user.profileImage) {
        const oldImagePath = path.join(process.cwd(), user.profileImage);
        if (fs.existsSync(oldImagePath)) {
          fs.unlinkSync(oldImagePath);
        }
      }
      
      // Update user with new profile image path
      user.profileImage = req.file.path;
      await user.save();
      
      res.json({
        success: true,
        message: 'Profile image uploaded successfully',
        data: {
          profileImage: req.file.path,
          user: {
            id: user._id,
            name: user.name,
            email: user.email
          }
        }
      });
    } catch (err) {
      console.error('Error uploading image:', err);
      res.status(500).json({
        success: false,
        message: 'Error uploading image',
        error: err.message
      });
    }
  }
);

// Remove profile image
router.delete('/profile-image', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Delete image file if exists
    if (user.profileImage) {
      const imagePath = path.join(process.cwd(), user.profileImage);
      if (fs.existsSync(imagePath)) {
        fs.unlinkSync(imagePath);
      }
    }
    
    // Remove image reference from user
    user.profileImage = '';
    await user.save();
    
    res.json({
      success: true,
      message: 'Profile image removed successfully'
    });
  } catch (err) {
    console.error('Error removing image:', err);
    res.status(500).json({
      success: false,
      message: 'Error removing image',
      error: err.message
    });
  }
});

export default router;