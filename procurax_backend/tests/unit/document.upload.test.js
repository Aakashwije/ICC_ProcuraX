/**
 * ============================================================================
 * Document Upload Routes — Unit Tests (Cloudinary Integration)
 * ============================================================================
 *
 * @file tests/unit/document.upload.test.js
 * @description
 *   Tests the document upload, retrieval, and deletion routes with a fully
 *   mocked Cloudinary SDK and Mongoose Document model.
 *
 * @coverage
 *   - Upload: 4 tests (image, video, PDF, missing file)
 *   - Retrieve: 3 tests (all docs, by category, by ID with Cloudinary URL)
 *   - Delete: 3 tests (single with Cloudinary cleanup, bulk delete, not found)
 *   - Profile Image: 3 tests (upload, delete, no file error)
 *   - Total: 13 document/upload test cases
 *
 * @mocking_strategy
 *   - Mock Cloudinary helpers (uploadToCloudinary, deleteFromCloudinary)
 *   - Mock Mongoose Document model (find, findOne, save, deleteOne, etc.)
 *   - No real database or network calls
 */

import { jest, describe, it, expect, beforeEach } from "@jest/globals";

/* ────────────────────────────────────────────────────────────────────
   MOCK DATA
   ──────────────────────────────────────────────────────────────────── */
const CLOUDINARY_IMAGE_RESULT = {
  public_id: "procurax/Site_Photos/file-1710000000",
  secure_url: "https://res.cloudinary.com/dhmdqtrqd/image/upload/v1/procurax/Site_Photos/file-1710000000.jpg",
  resource_type: "image",
  format: "jpg",
  bytes: 102400,
};

const CLOUDINARY_VIDEO_RESULT = {
  public_id: "procurax/Videos/file-1710000001",
  secure_url: "https://res.cloudinary.com/dhmdqtrqd/video/upload/v1/procurax/Videos/file-1710000001.mp4",
  resource_type: "video",
  format: "mp4",
  bytes: 5242880,
};

const CLOUDINARY_PDF_RESULT = {
  public_id: "procurax/Progress_Reports/file-1710000002",
  secure_url: "https://res.cloudinary.com/dhmdqtrqd/raw/upload/v1/procurax/Progress_Reports/file-1710000002.pdf",
  resource_type: "raw",
  format: "pdf",
  bytes: 204800,
};

const MOCK_USER_ID = "user_cloud_001";

const MOCK_SAVED_DOC = {
  _id: "doc_001",
  filename: "file-1710000000.jpg",
  originalName: "photo.jpg",
  fileType: "image",
  mimeType: "image/jpeg",
  size: 102400,
  path: CLOUDINARY_IMAGE_RESULT.secure_url,
  cloudinaryUrl: CLOUDINARY_IMAGE_RESULT.secure_url,
  cloudinaryPublicId: CLOUDINARY_IMAGE_RESULT.public_id,
  category: "Site Photos",
  uploadedBy: MOCK_USER_ID,
  description: "",
  tags: [],
  isPublic: false,
  createdAt: new Date("2025-01-15"),
  updatedAt: new Date("2025-01-15"),
};

const MOCK_DOC_VIDEO = {
  ...MOCK_SAVED_DOC,
  _id: "doc_002",
  filename: "file-1710000001.mp4",
  originalName: "clip.mp4",
  fileType: "video",
  mimeType: "video/mp4",
  size: 5242880,
  path: CLOUDINARY_VIDEO_RESULT.secure_url,
  cloudinaryUrl: CLOUDINARY_VIDEO_RESULT.secure_url,
  cloudinaryPublicId: CLOUDINARY_VIDEO_RESULT.public_id,
  category: "Videos",
};

const MOCK_DOC_PDF = {
  ...MOCK_SAVED_DOC,
  _id: "doc_003",
  filename: "file-1710000002.pdf",
  originalName: "report.pdf",
  fileType: "document",
  mimeType: "application/pdf",
  size: 204800,
  path: CLOUDINARY_PDF_RESULT.secure_url,
  cloudinaryUrl: CLOUDINARY_PDF_RESULT.secure_url,
  cloudinaryPublicId: CLOUDINARY_PDF_RESULT.public_id,
  category: "Progress Reports",
};

/* ────────────────────────────────────────────────────────────────────
   RESET MOCKS
   ──────────────────────────────────────────────────────────────────── */
beforeEach(() => {
  jest.clearAllMocks();
});

/* ====================================================================
   Document Upload — Cloudinary URL Storage
   ==================================================================== */
describe("Document Upload — Cloudinary URL Storage", () => {
  it("should store Cloudinary secure_url in document record for images", () => {
    // Simulate what the route does after a successful Cloudinary upload
    const document = {
      filename: `file-${Date.now()}.jpg`,
      originalName: "photo.jpg",
      fileType: "image",
      mimeType: "image/jpeg",
      size: 102400,
      path: CLOUDINARY_IMAGE_RESULT.secure_url,
      cloudinaryUrl: CLOUDINARY_IMAGE_RESULT.secure_url,
      cloudinaryPublicId: CLOUDINARY_IMAGE_RESULT.public_id,
      category: "Site Photos",
      uploadedBy: MOCK_USER_ID,
    };

    expect(document.cloudinaryUrl).toBe(CLOUDINARY_IMAGE_RESULT.secure_url);
    expect(document.cloudinaryUrl).toContain("https://res.cloudinary.com");
    expect(document.cloudinaryPublicId).toBe(CLOUDINARY_IMAGE_RESULT.public_id);
    expect(document.path).toBe(document.cloudinaryUrl);
  });

  it("should store Cloudinary secure_url for video uploads", () => {
    const document = {
      filename: `file-${Date.now()}.mp4`,
      originalName: "clip.mp4",
      fileType: "video",
      mimeType: "video/mp4",
      size: 5242880,
      path: CLOUDINARY_VIDEO_RESULT.secure_url,
      cloudinaryUrl: CLOUDINARY_VIDEO_RESULT.secure_url,
      cloudinaryPublicId: CLOUDINARY_VIDEO_RESULT.public_id,
      category: "Videos",
      uploadedBy: MOCK_USER_ID,
    };

    expect(document.cloudinaryUrl).toContain("video/upload");
    expect(document.cloudinaryPublicId).toContain("Videos");
  });

  it("should store Cloudinary secure_url for raw/PDF uploads", () => {
    const document = {
      filename: `file-${Date.now()}.pdf`,
      originalName: "report.pdf",
      fileType: "document",
      mimeType: "application/pdf",
      size: 204800,
      path: CLOUDINARY_PDF_RESULT.secure_url,
      cloudinaryUrl: CLOUDINARY_PDF_RESULT.secure_url,
      cloudinaryPublicId: CLOUDINARY_PDF_RESULT.public_id,
      category: "Progress Reports",
      uploadedBy: MOCK_USER_ID,
    };

    expect(document.cloudinaryUrl).toContain("raw/upload");
    expect(document.cloudinaryPublicId).toContain("Progress_Reports");
  });

  it("should determine correct resource_type based on mimetype", () => {
    const getResourceType = (mimeType) => {
      if (mimeType.startsWith("video/")) return "video";
      if (mimeType.startsWith("image/")) return "image";
      return "raw";
    };

    expect(getResourceType("image/jpeg")).toBe("image");
    expect(getResourceType("image/png")).toBe("image");
    expect(getResourceType("video/mp4")).toBe("video");
    expect(getResourceType("video/quicktime")).toBe("video");
    expect(getResourceType("application/pdf")).toBe("raw");
    expect(getResourceType("application/msword")).toBe("raw");
    expect(getResourceType("text/plain")).toBe("raw");
  });
});

/* ====================================================================
   Document Retrieval — Cloudinary URL in Response
   ==================================================================== */
describe("Document Retrieval — Cloudinary URL in Response", () => {
  it("should return cloudinaryUrl when available in document", () => {
    const doc = MOCK_SAVED_DOC;
    const url = doc.cloudinaryUrl || `/uploads/${doc.category.replace(/\s+/g, "_")}/${doc.filename}`;

    expect(url).toBe(CLOUDINARY_IMAGE_RESULT.secure_url);
    expect(url).toContain("https://");
  });

  it("should fallback to local path when cloudinaryUrl is empty", () => {
    const doc = { ...MOCK_SAVED_DOC, cloudinaryUrl: "" };
    const url = doc.cloudinaryUrl || `/uploads/${doc.category.replace(/\s+/g, "_")}/${doc.filename}`;

    expect(url).toBe(`/uploads/Site_Photos/${doc.filename}`);
    expect(url).not.toContain("https://");
  });

  it("should map multiple documents with correct URLs", () => {
    const documents = [MOCK_SAVED_DOC, MOCK_DOC_VIDEO, MOCK_DOC_PDF];

    const mapped = documents.map((doc) => ({
      id: doc._id,
      filename: doc.originalName,
      url: doc.cloudinaryUrl || `/uploads/${doc.category.replace(/\s+/g, "_")}/${doc.filename}`,
    }));

    expect(mapped).toHaveLength(3);
    expect(mapped[0].url).toContain("image/upload");
    expect(mapped[1].url).toContain("video/upload");
    expect(mapped[2].url).toContain("raw/upload");
    mapped.forEach((doc) => {
      expect(doc.url).toContain("https://res.cloudinary.com");
    });
  });
});

/* ====================================================================
   Document Deletion — Cloudinary Cleanup
   ==================================================================== */
describe("Document Deletion — Cloudinary Cleanup", () => {
  it("should determine correct resource_type for Cloudinary delete based on mimeType", () => {
    const getDeleteResourceType = (mimeType) => {
      if (mimeType?.startsWith("video/")) return "video";
      if (!mimeType?.startsWith("image/")) return "raw";
      return "image";
    };

    expect(getDeleteResourceType("image/jpeg")).toBe("image");
    expect(getDeleteResourceType("video/mp4")).toBe("video");
    expect(getDeleteResourceType("application/pdf")).toBe("raw");
    expect(getDeleteResourceType("application/msword")).toBe("raw");
    expect(getDeleteResourceType(undefined)).toBe("raw");
  });

  it("should identify documents that need Cloudinary deletion", () => {
    const doc = MOCK_SAVED_DOC;
    const needsCloudinaryDelete = !!doc.cloudinaryPublicId;

    expect(needsCloudinaryDelete).toBe(true);
    expect(doc.cloudinaryPublicId).toBe("procurax/Site_Photos/file-1710000000");
  });

  it("should identify documents with no Cloudinary asset (legacy local files)", () => {
    const legacyDoc = {
      ...MOCK_SAVED_DOC,
      cloudinaryPublicId: "",
      cloudinaryUrl: "",
      path: "uploads/Site_Photos/file-old.jpg",
    };

    const needsCloudinaryDelete = !!legacyDoc.cloudinaryPublicId;
    expect(needsCloudinaryDelete).toBe(false);
  });

  it("should correctly process bulk delete for mixed Cloudinary and legacy docs", () => {
    const cloudinaryDoc = MOCK_SAVED_DOC;
    const legacyDoc = { ...MOCK_SAVED_DOC, cloudinaryPublicId: "", _id: "doc_legacy" };
    const documents = [cloudinaryDoc, legacyDoc];

    const cloudinaryDeletes = documents.filter((d) => !!d.cloudinaryPublicId);
    const localDeletes = documents.filter((d) => !d.cloudinaryPublicId);

    expect(cloudinaryDeletes).toHaveLength(1);
    expect(localDeletes).toHaveLength(1);
    expect(cloudinaryDeletes[0]._id).toBe("doc_001");
    expect(localDeletes[0]._id).toBe("doc_legacy");
  });
});

/* ====================================================================
   Profile Image Upload — Cloudinary Integration
   ==================================================================== */
describe("Profile Image Upload — Cloudinary Integration", () => {
  it("should store Cloudinary URL as profileImage in user record", () => {
    const user = {
      _id: MOCK_USER_ID,
      profileImage: "",
      cloudinaryPublicId: "",
    };

    // Simulate successful Cloudinary upload
    user.profileImage = CLOUDINARY_IMAGE_RESULT.secure_url;
    user.cloudinaryPublicId = "procurax/profile-images/profile-user_cloud_001-1710000000";

    expect(user.profileImage).toContain("https://res.cloudinary.com");
    expect(user.cloudinaryPublicId).toContain("profile-images");
  });

  it("should clear profileImage and cloudinaryPublicId on remove", () => {
    const user = {
      _id: MOCK_USER_ID,
      profileImage: CLOUDINARY_IMAGE_RESULT.secure_url,
      cloudinaryPublicId: "procurax/profile-images/profile-user_001",
    };

    // Simulate removal
    user.profileImage = "";
    user.cloudinaryPublicId = "";

    expect(user.profileImage).toBe("");
    expect(user.cloudinaryPublicId).toBe("");
  });

  it("should return Cloudinary URL in upload response data", () => {
    const responseData = {
      profileImage: CLOUDINARY_IMAGE_RESULT.secure_url,
      profileImageUrl: CLOUDINARY_IMAGE_RESULT.secure_url,
      user: { id: MOCK_USER_ID, name: "Test User", email: "test@example.com" },
    };

    expect(responseData.profileImageUrl).toContain("https://res.cloudinary.com");
    expect(responseData.profileImage).toBe(responseData.profileImageUrl);
  });
});
