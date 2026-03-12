import express from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import authMiddleware from  "../../auth/auth.middleware.js";
import User from '../../models/User.js';

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
      console.log('Resolved upload file:', file);

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
      user.profileImage = file.path;
      await user.save();

      // Expose a URL that can be used by the client to load the image.
      const baseUrl = `${req.protocol}://${req.get('host')}`;
      const relativePath = file.path.split(path.sep).join('/');
      const profileImageUrl = `${baseUrl}/${relativePath}`;

      res.json({
        success: true,
        message: 'Profile image uploaded successfully',
        data: {
          profileImage: file.path,
          profileImageUrl,
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