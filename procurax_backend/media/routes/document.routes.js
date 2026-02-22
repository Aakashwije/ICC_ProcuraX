import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from 'url';
import Document from "../models/document.model.js";
import { authenticateToken } from "../middleware/auth.middleware.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

// Create uploads directory if it doesn't exist
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
  console.log('✅ Uploads directory created');
}

// Configure multer storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Get category from request body
    const category = req.body.category || 'Other';
    // Replace spaces with underscores for folder name
    const categoryFolder = category.replace(/\s+/g, '_');
    const categoryDir = path.join(uploadDir, categoryFolder);
    
    // Create category directory if it doesn't exist
    if (!fs.existsSync(categoryDir)) {
      fs.mkdirSync(categoryDir, { recursive: true });
    }
    cb(null, categoryDir);
  },
  filename: function (req, file, cb) {
    // Create unique filename with timestamp
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, 'file-' + uniqueSuffix + ext);
  }
});

// File filter function
const fileFilter = (req, file, cb) => {
  // Allowed file types
  const allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
  const allowedVideoTypes = ['video/mp4', 'video/mpeg', 'video/quicktime', 'video/webm'];
  const allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain'
  ];
  const allowedBlueprintTypes = ['application/pdf', 'image/jpeg', 'image/png'];

  // Check if file type is allowed
  if (allowedImageTypes.includes(file.mimetype) ||
      allowedVideoTypes.includes(file.mimetype) ||
      allowedDocumentTypes.includes(file.mimetype) ||
      allowedBlueprintTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Please upload images, videos, PDFs, or documents only.'), false);
  }
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

// 1. UPLOAD DOCUMENT
router.post('/upload', authenticateToken, upload.single('file'), async (req, res) => {
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

    // Create document record in database
    const document = new Document({
      filename: req.file.filename,
      originalName: req.file.originalname,
      fileType: documentType,
      mimeType: req.file.mimetype,
      size: req.file.size,
      path: req.file.path,
      category: category || 'Other',
      uploadedBy: req.userId,
      description: description || '',
      tags: tags ? (typeof tags === 'string' ? JSON.parse(tags) : tags) : [],
      isPublic: isPublic === 'true' || isPublic === true
    });

    await document.save();

    // Generate URL for the file
    const categoryFolder = (category || 'Other').replace(/\s+/g, '_');
    const fileUrl = `/uploads/${categoryFolder}/${req.file.filename}`;

    res.status(201).json({
      success: true,
      message: 'Document uploaded successfully',
      document: {
        id: document._id,
        filename: document.originalName,
        fileType: document.fileType,
        size: document.size,
        category: document.category,
        url: fileUrl,
        uploadedAt: document.createdAt
      }
    });

  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
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

    // Add URLs to documents
    const documentsWithUrls = documents.map(doc => {
      const categoryFolder = doc.category.replace(/\s+/g, '_');
      return {
        id: doc._id,
        filename: doc.originalName,
        fileType: doc.fileType,
        mimeType: doc.mimeType,
        size: doc.size,
        category: doc.category,
        description: doc.description,
        tags: doc.tags,
        url: `/uploads/${categoryFolder}/${doc.filename}`,
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
      message: error.message 
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
      const categoryFolder = doc.category.replace(/\s+/g, '_');
      return {
        id: doc._id,
        filename: doc.originalName,
        fileType: doc.fileType,
        mimeType: doc.mimeType,
        size: doc.size,
        category: doc.category,
        description: doc.description,
        tags: doc.tags,
        url: `/uploads/${categoryFolder}/${doc.filename}`,
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

    const categoryFolder = document.category.replace(/\s+/g, '_');
    
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
        url: `/uploads/${categoryFolder}/${document.filename}`,
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

    // Delete file from storage
    try {
      if (fs.existsSync(document.path)) {
        fs.unlinkSync(document.path);
        console.log(`File deleted: ${document.path}`);
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

    // Delete files from storage
    for (const doc of documents) {
      try {
        if (fs.existsSync(doc.path)) {
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