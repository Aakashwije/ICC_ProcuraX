import express from 'express';
import multer from 'multer';
import { uploadFile, downloadFile } from '../controllers/fileController.js';

const router = express.Router();

// Configure multer for file uploads
const storage = multer.memoryStorage();

// Validate file types
function fileFilter(req, file, cb) {
  const allowedMimeTypes = [
    // Allowed
    'image/png',
    'application/pdf',
  ];

  // Allow only specific file types
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only images, videos, and documents are allowed.'));
  }
}

// Initialize multer with storage and file filter
const upload = multer({ storage, fileFilter });

//Upload a file 
// Used for uploading files
// POST /api/files/upload - Upload a file
router.post('/upload', upload.single('file'), uploadFile);

// Download a file by name
// User when user taps  an attachment
// GET /api/files/download/:fileName - Download a file by filename
router.get('/download/:fileName', downloadFile);

export default router;
