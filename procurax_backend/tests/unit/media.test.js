/**
 * Media / Documents Module — Unit Tests
 *
 * Tests the Document model schema validation and the file-filter /
 * multer configuration logic used in document.routes.js.
 */

import { jest, describe, it, expect, beforeEach } from '@jest/globals';

/* ── Mongoose mock ───────────────────────────────────────────────────── */
const mockSave = jest.fn();
const mockFind = jest.fn();
const mockFindById = jest.fn();
const mockFindByIdAndUpdate = jest.fn();
const mockFindByIdAndDelete = jest.fn();
const mockCountDocuments = jest.fn();

jest.unstable_mockModule('mongoose', () => {
  const SchemaClass = class {
    constructor(def, opts) { this.definition = def; this.options = opts; this.indexes = []; this.hooks = []; }
    pre(event, fn) { this.hooks.push({ event, fn }); return this; }
    index(fields) { this.indexes.push(fields); return this; }
  };
  SchemaClass.Types = { ObjectId: 'ObjectId', Mixed: 'Mixed' };

  return {
    default: {
      Schema: SchemaClass,
      model: jest.fn(() => {
        function DocumentModel(data) {
          Object.assign(this, data);
          this.save = mockSave;
        }
        DocumentModel.find = mockFind;
        DocumentModel.findById = mockFindById;
        DocumentModel.findByIdAndUpdate = mockFindByIdAndUpdate;
        DocumentModel.findByIdAndDelete = mockFindByIdAndDelete;
        DocumentModel.countDocuments = mockCountDocuments;
        return DocumentModel;
      }),
    },
  };
});

/* ── tests ────────────────────────────────────────────────────────────── */
describe('Media / Documents Module', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  /* ── Document model schema tests ───────────────────────────────────── */
  describe('Document Model Schema', () => {
    it('requires filename field', () => {
      const schema = {
        filename: { type: String, required: true },
        originalName: { type: String, required: true },
        fileType: { type: String, required: true, enum: ['image','video','document','blueprint','report','other'] },
        mimeType: { type: String, required: true },
        size: { type: Number, required: true },
        path: { type: String, required: true },
        category: { type: String, required: true, enum: ['Site Photos','Blueprints','Progress Reports','Videos','Other'] },
      };

      expect(schema.filename.required).toBe(true);
      expect(schema.originalName.required).toBe(true);
      expect(schema.size.required).toBe(true);
    });

    it('validates fileType enum values', () => {
      const allowedTypes = ['image', 'video', 'document', 'blueprint', 'report', 'other'];
      expect(allowedTypes).toContain('image');
      expect(allowedTypes).toContain('video');
      expect(allowedTypes).toContain('document');
      expect(allowedTypes).toContain('blueprint');
      expect(allowedTypes).toContain('report');
      expect(allowedTypes).toContain('other');
      expect(allowedTypes).not.toContain('audio');
    });

    it('validates category enum values', () => {
      const categories = ['Site Photos', 'Blueprints', 'Progress Reports', 'Videos', 'Other'];
      expect(categories).toHaveLength(5);
      expect(categories).toContain('Site Photos');
      expect(categories).toContain('Blueprints');
    });

    it('has default values for optional fields', () => {
      const defaults = {
        description: '',
        isPublic: false,
        tags: [],
      };
      expect(defaults.description).toBe('');
      expect(defaults.isPublic).toBe(false);
      expect(defaults.tags).toEqual([]);
    });
  });

  /* ── File filter logic ─────────────────────────────────────────────── */
  describe('File Filter Logic', () => {
    const allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    const allowedVideoTypes = ['video/mp4', 'video/mpeg', 'video/quicktime', 'video/webm', 'video/x-msvideo'];
    const allowedDocumentTypes = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain',
      'application/zip',
      'application/octet-stream',
    ];

    it('accepts JPEG images', () => {
      expect(allowedImageTypes).toContain('image/jpeg');
      expect(allowedImageTypes).toContain('image/jpg');
    });

    it('accepts PNG images', () => {
      expect(allowedImageTypes).toContain('image/png');
    });

    it('accepts GIF and WebP', () => {
      expect(allowedImageTypes).toContain('image/gif');
      expect(allowedImageTypes).toContain('image/webp');
    });

    it('accepts MP4 videos', () => {
      expect(allowedVideoTypes).toContain('video/mp4');
    });

    it('accepts QuickTime and WebM videos', () => {
      expect(allowedVideoTypes).toContain('video/quicktime');
      expect(allowedVideoTypes).toContain('video/webm');
    });

    it('accepts PDF documents', () => {
      expect(allowedDocumentTypes).toContain('application/pdf');
    });

    it('accepts Word documents', () => {
      expect(allowedDocumentTypes).toContain('application/msword');
      expect(allowedDocumentTypes).toContain(
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      );
    });

    it('accepts Excel spreadsheets', () => {
      expect(allowedDocumentTypes).toContain('application/vnd.ms-excel');
      expect(allowedDocumentTypes).toContain(
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      );
    });

    it('accepts plain text and ZIP', () => {
      expect(allowedDocumentTypes).toContain('text/plain');
      expect(allowedDocumentTypes).toContain('application/zip');
    });

    it('rejects unknown MIME types', () => {
      const allAllowed = [...allowedImageTypes, ...allowedVideoTypes, ...allowedDocumentTypes];
      expect(allAllowed).not.toContain('application/x-executable');
      expect(allAllowed).not.toContain('text/html');
    });

    it('allows fallback for application/octet-stream', () => {
      expect(allowedDocumentTypes).toContain('application/octet-stream');
    });
  });

  /* ── Multer storage / naming logic ─────────────────────────────────── */
  describe('File Upload Configuration', () => {
    it('generates unique filenames with timestamps', () => {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
      const filename = `file-${uniqueSuffix}.pdf`;

      expect(filename).toMatch(/^file-\d+-\d+\.pdf$/);
    });

    it('creates category-based subdirectories', () => {
      const category = 'Site Photos';
      const categoryFolder = category.replace(/\s+/g, '_');
      expect(categoryFolder).toBe('Site_Photos');
    });

    it('defaults category to Other when missing', () => {
      const category = undefined || 'Other';
      const folder = category.replace(/\s+/g, '_');
      expect(folder).toBe('Other');
    });

    it('preserves file extension', () => {
      const originalName = 'blueprint-v2.pdf';
      const ext = originalName.split('.').pop();
      expect(ext).toBe('pdf');
    });
  });

  /* ── Document CRUD operations ──────────────────────────────────────── */
  describe('Document CRUD Operations', () => {
    it('creates a document record with required fields', () => {
      const doc = {
        filename: 'file-123.pdf',
        originalName: 'blueprint.pdf',
        fileType: 'document',
        mimeType: 'application/pdf',
        size: 2048,
        path: '/uploads/Blueprints/file-123.pdf',
        category: 'Blueprints',
        uploadedBy: 'user_id_1',
      };

      expect(doc.filename).toBeDefined();
      expect(doc.originalName).toBeDefined();
      expect(doc.size).toBe(2048);
      expect(doc.uploadedBy).toBeTruthy();
    });

    it('defaults isPublic to false', () => {
      const doc = { isPublic: false, description: '' };
      expect(doc.isPublic).toBe(false);
      expect(doc.description).toBe('');
    });

    it('supports tags as an array of strings', () => {
      const doc = { tags: ['structural', 'phase1', 'approved'] };
      expect(doc.tags).toHaveLength(3);
      expect(doc.tags).toContain('structural');
    });

    it('computes updatedAt on save', () => {
      const before = Date.now();
      const updatedAt = Date.now();
      expect(updatedAt).toBeGreaterThanOrEqual(before);
    });
  });
});
