import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from 'url';
import Document from "../models/document.model.js";
import { authenticateToken } from "../middleware/auth.middleware.js";
import { uploadToCloudinary, deleteFromCloudinary } from "../../config/cloudinary.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

// Configure multer to use MEMORY storage (file buffer for Cloudinary upload)
const storage = multer.memoryStorage();

// File filter function
const fileFilter = (req, file, cb) => {
  // Allowed file types
  const allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
  const allowedVideoTypes = ['video/mp4', 'video/mpeg', 'video/quicktime', 'video/webm', 'video/x-msvideo'];
  const allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain',
    'application/zip',
    'application/octet-stream',
  ];
  const allowedBlueprintTypes = ['application/pdf', 'image/jpeg', 'image/png'];

  // Allow unknown/empty mime types (some platforms may not send correct type)
  if (!file.mimetype || file.mimetype === 'application/octet-stream') {
    return cb(null, true);
  }

  // Check if file type is allowed
  if (
    allowedImageTypes.includes(file.mimetype) ||
    allowedVideoTypes.includes(file.mimetype) ||
    allowedDocumentTypes.includes(file.mimetype) ||
    allowedBlueprintTypes.includes(file.mimetype)
  ) {
    return cb(null, true);
  }

  // Reject unknown file types
  cb(new Error('Invalid file type. Please upload images, videos, PDFs, or documents only.'), false);
};

// Configure multer upload
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB limit
  }
});

// Helper function to determine file type
const getDocumentType = (category, mimeType) => {
  if (category === 'Site Photos') return 'image';
  if (category === 'Videos') return 'video';
  if (category === 'Blueprints') return 'blueprint';
  if (category === 'Progress Reports') return 'report';
  
  if (mimeType.startsWith('image/')) return 'image';
  if (mimeType.startsWith('video/')) return 'video';
  if (mimeType.includes('pdf')) return 'document';
  if (mimeType.includes('word')) return 'document';
  if (mimeType.includes('excel')) return 'document';
  return 'other';
};

// ==================== API ROUTES ====================

// 1. UPLOAD DOCUMENT (to Cloudinary)
router.post('/upload', authenticateToken, upload.single('file'), async (req, res) => {
  console.log('[DOC UPLOAD] received upload request for', req.originalUrl);
  try {
    if (!req.file) {
      return res.status(400).json({ 
        success: false,
        message: 'No file uploaded' 
      });
    }

    const { category, description, tags, isPublic } = req.body;
    
    // Determine file type
    const documentType = getDocumentType(category, req.file.mimetype);

    // Determine Cloudinary resource_type based on mime
    let resourceType = 'auto';
    if (req.file.mimetype.startsWith('video/')) resourceType = 'video';
    else if (req.file.mimetype.startsWith('image/')) resourceType = 'image';
    else resourceType = 'raw'; // PDFs, docs, etc.

    // Upload to Cloudinary from buffer
    // folder and public_id are sanitized inside uploadToCloudinary() to avoid "Display name cannot contain slashes" error
    const sanitizedCategory = (category || 'Other').replaceAll(/\s+/g, '_');
    const cloudinaryResult = await uploadToCloudinary(
      `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`,
      {
        resource_type: resourceType,
        folder: `procurax/${sanitizedCategory}`,
        public_id: `file-${Date.now()}`,
      }
    );

    console.log('[DOC UPLOAD] Cloudinary result:', cloudinaryResult.secure_url);

    // Create document record in database with Cloudinary URL
    const document = new Document({
      filename: `file-${Date.now()}${path.extname(req.file.originalname)}`,
      originalName: req.file.originalname,
      fileType: documentType,
      mimeType: req.file.mimetype,
      size: req.file.size,
      path: cloudinaryResult.secure_url,          // store cloud URL as path
      cloudinaryUrl: cloudinaryResult.secure_url,
      cloudinaryPublicId: cloudinaryResult.public_id,
      category: category || 'Other',
      uploadedBy: req.userId,
      description: description || '',
      tags: tags ? (typeof tags === 'string' ? JSON.parse(tags) : tags) : [],
      isPublic: isPublic === 'true' || isPublic === true
    });

    await document.save();

    res.status(201).json({
      success: true,
      message: 'Document uploaded successfully',
      document: {
        id: document._id,
        filename: document.originalName,
        fileType: document.fileType,
        size: document.size,
        category: document.category,
        url: cloudinaryResult.secure_url,
        uploadedAt: document.createdAt
      }
    });

  } catch (error) {
    console.error('Upload error:', error);

    // Return client-friendly errors for common upload failures
    if (error?.message?.includes('Invalid file type')) {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }

    // Multer limit errors (e.g., file size)
    if (error?.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: 'File is too large. Maximum upload size is 100MB.',
      });
    }

    res.status(500).json({ 
      success: false,
      message: 'Internal Server Error',
    });
  }
});

// 2. GET ALL DOCUMENTS FOR CURRENT USER
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { category, search } = req.query;
    
    // Build query
    let query = { uploadedBy: req.userId };
    
    if (category) {
      query.category = category;
    }
    
    if (search) {
      query.originalName = { $regex: search, $options: 'i' };
    }

    // Fetch documents from database
    const documents = await Document.find(query)
      .sort({ createdAt: -1 });

    // Add URLs to documents (use Cloudinary URL if available, fallback to local)
    const documentsWithUrls = documents.map(doc => {
      return {
        id: doc._id,
        filename: doc.originalName,
        fileType: doc.fileType,
        mimeType: doc.mimeType,
        size: doc.size,
        category: doc.category,
        description: doc.description,
        tags: doc.tags,
        url: doc.cloudinaryUrl || `/uploads/${doc.category.replace(/\s+/g, '_')}/${doc.filename}`,
        uploadedAt: doc.createdAt
      };
    });

    // Group documents by category
    const groupedDocs = documentsWithUrls.reduce((acc, doc) => {
      if (!acc[doc.category]) {
        acc[doc.category] = [];
      }
      acc[doc.category].push(doc);
      return acc;
    }, {});

    // Create category summaries
    const categories = Object.keys(groupedDocs).map(categoryName => ({
      name: categoryName,
      count: groupedDocs[categoryName].length,
      totalSize: groupedDocs[categoryName].reduce((sum, doc) => sum + doc.size, 0),
      files: groupedDocs[categoryName]
    }));

    res.json({
      success: true,
      documents: documentsWithUrls,
      grouped: groupedDocs,
      categories: categories,
      totalDocuments: documentsWithUrls.length,
      totalSize: documentsWithUrls.reduce((sum, doc) => sum + doc.size, 0)
    });

  } catch (error) {
    console.error('Error fetching documents:', error);
    res.status(500).json({ 
      success: false,
      message: error.message,
      categories: [],
      documents: [],
      totalDocuments: 0,
      totalSize: 0
    });
  }
});

// 3. GET DOCUMENTS BY CATEGORY
router.get('/category/:category', authenticateToken, async (req, res) => {
  try {
    const documents = await Document.find({
      uploadedBy: req.userId,
      category: req.params.category
    }).sort({ createdAt: -1 });

    const documentsWithUrls = documents.map(doc => {
      return {
        id: doc._id,
        filename: doc.originalName,
        fileType: doc.fileType,
        mimeType: doc.mimeType,
        size: doc.size,
        category: doc.category,
        description: doc.description,
        tags: doc.tags,
        url: doc.cloudinaryUrl || `/uploads/${doc.category.replace(/\s+/g, '_')}/${doc.filename}`,
        uploadedAt: doc.createdAt
      };
    });

    res.json({
      success: true,
      category: req.params.category,
      count: documentsWithUrls.length,
      documents: documentsWithUrls
    });

  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// 4. GET SINGLE DOCUMENT BY ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const document = await Document.findOne({
      _id: req.params.id,
      uploadedBy: req.userId
    });

    if (!document) {
      return res.status(404).json({ 
        success: false,
        message: 'Document not found' 
      });
    }

    res.json({
      success: true,
      document: {
        id: document._id,
        filename: document.originalName,
        fileType: document.fileType,
        mimeType: document.mimeType,
        size: document.size,
        category: document.category,
        description: document.description,
        tags: document.tags,
        url: document.cloudinaryUrl || `/uploads/${document.category.replace(/\s+/g, '_')}/${document.filename}`,
        uploadedAt: document.createdAt,
        updatedAt: document.updatedAt
      }
    });

  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// 5. UPDATE DOCUMENT METADATA
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { filename, category, description, tags, isPublic } = req.body;
    
    const document = await Document.findOneAndUpdate(
      { _id: req.params.id, uploadedBy: req.userId },
      { 
        ...(filename && { originalName: filename }),
        ...(category && { category }),
        ...(description !== undefined && { description }),
        ...(tags && { tags: typeof tags === 'string' ? JSON.parse(tags) : tags }),
        ...(isPublic !== undefined && { isPublic }),
        updatedAt: Date.now()
      },
      { new: true }
    );

    if (!document) {
      return res.status(404).json({ 
        success: false,
        message: 'Document not found' 
      });
    }

    res.json({
      success: true,
      message: 'Document updated successfully',
      document: {
        id: document._id,
        filename: document.originalName,
        category: document.category,
        description: document.description,
        tags: document.tags,
        isPublic: document.isPublic
      }
    });

  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// 6. DELETE DOCUMENT
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    // Find document
    const document = await Document.findOne({
      _id: req.params.id,
      uploadedBy: req.userId
    });

    if (!document) {
      return res.status(404).json({ 
        success: false,
        message: 'Document not found' 
      });
    }

    // Delete file from Cloudinary if it was stored there, otherwise try local
    try {
      if (document.cloudinaryPublicId) {
        // Determine resource type for Cloudinary deletion
        let resType = 'image';
        if (document.mimeType?.startsWith('video/')) resType = 'video';
        else if (!document.mimeType?.startsWith('image/')) resType = 'raw';
        await deleteFromCloudinary(document.cloudinaryPublicId, resType);
        console.log(`Cloudinary file deleted: ${document.cloudinaryPublicId}`);
      } else if (document.path && fs.existsSync(document.path)) {
        fs.unlinkSync(document.path);
        console.log(`Local file deleted: ${document.path}`);
      }
    } catch (fileError) {
      console.error('Error deleting file:', fileError);
    }

    // Delete from database
    await Document.deleteOne({ _id: document._id });

    res.json({ 
      success: true,
      message: 'Document deleted successfully' 
    });

  } catch (error) {
    console.error('Delete error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// 7. BULK DELETE DOCUMENTS
router.post('/bulk-delete', authenticateToken, async (req, res) => {
  try {
    const { documentIds } = req.body;
    
    if (!documentIds || !Array.isArray(documentIds) || documentIds.length === 0) {
      return res.status(400).json({ 
        success: false,
        message: 'No document IDs provided' 
      });
    }

    // Find all documents
    const documents = await Document.find({
      _id: { $in: documentIds },
      uploadedBy: req.userId
    });

    // Delete files from Cloudinary or local storage
    for (const doc of documents) {
      try {
        if (doc.cloudinaryPublicId) {
          let resType = 'image';
          if (doc.mimeType?.startsWith('video/')) resType = 'video';
          else if (!doc.mimeType?.startsWith('image/')) resType = 'raw';
          await deleteFromCloudinary(doc.cloudinaryPublicId, resType);
        } else if (doc.path && fs.existsSync(doc.path)) {
          fs.unlinkSync(doc.path);
        }
      } catch (fileError) {
        console.error('Error deleting file:', fileError);
      }
    }

    // Delete from database
    await Document.deleteMany({
      _id: { $in: documentIds },
      uploadedBy: req.userId
    });

    res.json({ 
      success: true,
      message: `${documents.length} document(s) deleted successfully` 
    });

  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

export default router;