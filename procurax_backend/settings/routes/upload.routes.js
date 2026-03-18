import express from 'express';
import multer from 'multer';
import path from 'path';
import { authMiddleware } from  "../../core/middleware/auth.middleware.js";
import User from '../../models/User.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../../config/cloudinary.js';

const router = express.Router();

// Use memory storage so we can upload the buffer to Cloudinary
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif/;
  const originalName = file.originalname || '';
  const mimeType = (file.mimetype || '').toLowerCase();
  const extname = allowedTypes.test(path.extname(originalName).toLowerCase());
  const mimetype = allowedTypes.test(mimeType);

  // Log for debugging purposes so we can see what the client is sending
  console.log('Multer fileFilter:', { originalName, mimeType, extname, mimetype });

  // Accept if either the file extension or the MIME type matches an allowed image type.
  // Some clients (e.g., certain mobile/image picker libraries) may omit or mis-report MIME types.
  if (mimetype || extname) {
    return cb(null, true);
  } else {
    cb(new Error(`Only image files are allowed (jpeg, jpg, png, gif). Received mimeType='${mimeType}' ext='${path.extname(originalName)}'`));
  }
};

const upload = multer({ 
  storage: storage,
  limits: { 
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: fileFilter
});

// Upload profile image
router.post(
  '/profile-image',
  authMiddleware,
  (req, res, next) => {
    // Use multer as middleware, but capture errors so we can return a useful message
    // Accept either 'profileImage' or 'file' as the field name (some clients use different names)
    upload.fields([
      { name: 'profileImage', maxCount: 1 },
      { name: 'file', maxCount: 1 }
    ])(req, res, (err) => {
      if (err) {
        console.error('Multer error on profile-image upload:', err);
        // multer errors are often due to file size/type; return 400 so client can interpret
        return res.status(400).json({
          success: false,
          message: err.message || 'Failed to upload image',
        });
      }
      next();
    });
  },
  async (req, res) => {
    try {
      console.log('Upload /profile-image called');
      console.log('Headers:', req.headers['content-type']);
      console.log('Files object:', req.files);
      console.log('Body:', req.body);

      const uploaded = (req.files?.profileImage ?? req.files?.file)?.[0];
      if (!uploaded) {
        return res.status(400).json({
          success: false,
          message: 'No file uploaded'
        });
      }

      const file = uploaded;
      console.log('Resolved upload file:', file.originalname);

      // Get user
      const user = await User.findById(req.userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      // Delete old profile image from Cloudinary if exists
      if (user.cloudinaryPublicId) {
        try {
          await deleteFromCloudinary(user.cloudinaryPublicId, 'image');
        } catch (delErr) {
          console.error('Error deleting old Cloudinary image:', delErr);
        }
      }

      // Upload new image to Cloudinary from buffer
      const cloudinaryResult = await uploadToCloudinary(
        `data:${file.mimetype};base64,${file.buffer.toString('base64')}`,
        {
          resource_type: 'image',
          folder: 'procurax/profile-images',
          public_id: `profile-${req.userId}-${Date.now()}`,
        }
      );

      console.log('Cloudinary profile upload result:', cloudinaryResult.secure_url);

      // Update user with Cloudinary URL
      user.profileImage = cloudinaryResult.secure_url;
      user.cloudinaryPublicId = cloudinaryResult.public_id;
      await user.save();

      res.json({
        success: true,
        message: 'Profile image uploaded successfully',
        data: {
          profileImage: cloudinaryResult.secure_url,
          profileImageUrl: cloudinaryResult.secure_url,
          user: {
            id: user._id,
            name: user.name,
            email: user.email
          }
        }
      });
    } catch (err) {
      console.error('Error uploading image:', err);
      if (err instanceof Error) {
        console.error(err.stack);
      }
      res.status(500).json({
        success: false,
        message: 'Error uploading image',
        error: err.message ?? String(err)
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
    
    // Delete image from Cloudinary if exists
    if (user.cloudinaryPublicId) {
      try {
        await deleteFromCloudinary(user.cloudinaryPublicId, 'image');
      } catch (delErr) {
        console.error('Error deleting Cloudinary image:', delErr);
      }
    }
    
    // Remove image reference from user
    user.profileImage = '';
    user.cloudinaryPublicId = '';
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