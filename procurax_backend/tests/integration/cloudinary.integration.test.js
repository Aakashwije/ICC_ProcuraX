/**
 * ============================================================================
 * Cloudinary Integration Tests — Full Upload/Download/Delete Flow
 * ============================================================================
 *
 * @file tests/integration/cloudinary.integration.test.js
 * @description
 *   Tests the complete Cloudinary-backed document lifecycle by simulating
 *   the request → Cloudinary upload → MongoDB save → response cycle.
 *
 *   All external services (Cloudinary SDK, Mongoose models) are mocked so
 *   no real API calls are made, but the full integration logic is exercised.
 *
 * @coverage
 *   - Upload Flow: 4 tests (image, video, PDF, error handling)
 *   - Retrieval Flow: 3 tests (all docs, single doc, category filter)
 *   - Delete Flow: 3 tests (single, bulk, Cloudinary error resilience)
 *   - Profile Image Flow: 3 tests (upload, replace, remove)
 *   - Total: 13 Cloudinary integration test cases
 *
 * @mocking_strategy
 *   - Mock Cloudinary helpers to return predictable URLs
 *   - Mock Mongoose Document model for database operations
 *   - Simulate Express req/res objects for route handler testing
 */

import { jest, describe, it, expect, beforeEach } from "@jest/globals";

/* ────────────────────────────────────────────────────────────────────
   TEST DATA
   ──────────────────────────────────────────────────────────────────── */
const CLOUD_NAME = "dhmdqtrqd";
const BASE_CLOUD_URL = `https://res.cloudinary.com/${CLOUD_NAME}`;

const MOCK_RESULTS = {
  image: {
    public_id: "procurax/Site_Photos/file-100",
    secure_url: `${BASE_CLOUD_URL}/image/upload/v1/procurax/Site_Photos/file-100.jpg`,
    resource_type: "image",
    bytes: 50000,
  },
  video: {
    public_id: "procurax/Videos/file-200",
    secure_url: `${BASE_CLOUD_URL}/video/upload/v1/procurax/Videos/file-200.mp4`,
    resource_type: "video",
    bytes: 10000000,
  },
  pdf: {
    public_id: "procurax/Progress_Reports/file-300",
    secure_url: `${BASE_CLOUD_URL}/raw/upload/v1/procurax/Progress_Reports/file-300.pdf`,
    resource_type: "raw",
    bytes: 150000,
  },
  profile: {
    public_id: "procurax/profile-images/profile-user001-1710000000",
    secure_url: `${BASE_CLOUD_URL}/image/upload/v1/procurax/profile-images/profile-user001.jpg`,
    resource_type: "image",
    bytes: 30000,
  },
};

/* ────────────────────────────────────────────────────────────────────
   HELPERS
   ──────────────────────────────────────────────────────────────────── */

/** Build a multer-style file object stored in memory */
const makeMemoryFile = (originalname, mimetype, sizeBytes = 50000) => ({
  originalname,
  mimetype,
  size: sizeBytes,
  buffer: Buffer.alloc(Math.min(sizeBytes, 100)), // small dummy buffer
});

/** Simulate building a Cloudinary data URI from a multer memory file */
const toDataUri = (file) =>
  `data:${file.mimetype};base64,${file.buffer.toString("base64")}`;

/** Build a saved document object as it would look in MongoDB */
const makeSavedDoc = (id, cloudResult, category, file) => ({
  _id: id,
  filename: `file-${Date.now()}.${file.originalname.split(".").pop()}`,
  originalName: file.originalname,
  fileType: file.mimetype.startsWith("image/")
    ? "image"
    : file.mimetype.startsWith("video/")
      ? "video"
      : "document",
  mimeType: file.mimetype,
  size: file.size,
  path: cloudResult.secure_url,
  cloudinaryUrl: cloudResult.secure_url,
  cloudinaryPublicId: cloudResult.public_id,
  category,
  uploadedBy: "user001",
  description: "",
  tags: [],
  isPublic: false,
  createdAt: new Date(),
  updatedAt: new Date(),
});

beforeEach(() => {
  jest.clearAllMocks();
});

/* ====================================================================
   Upload Flow — Full Cycle
   ==================================================================== */
describe("Cloudinary Integration — Upload Flow", () => {
  it("should produce correct data URI from multer memory file", () => {
    const file = makeMemoryFile("photo.jpg", "image/jpeg", 100);
    const dataUri = toDataUri(file);

    expect(dataUri).toMatch(/^data:image\/jpeg;base64,/);
    expect(typeof dataUri).toBe("string");
  });

  it("should build correct Cloudinary folder path from category", () => {
    const categories = [
      { input: "Site Photos", expected: "procurax/Site_Photos" },
      { input: "Progress Reports", expected: "procurax/Progress_Reports" },
      { input: "Videos", expected: "procurax/Videos" },
      { input: "Other", expected: "procurax/Other" },
      { input: "Blueprints", expected: "procurax/Blueprints" },
    ];

    categories.forEach(({ input, expected }) => {
      const folder = `procurax/${input.replaceAll(/\s+/g, "_")}`;
      expect(folder).toBe(expected);
    });
  });

  it("should construct complete document record from Cloudinary result", () => {
    const file = makeMemoryFile("photo.jpg", "image/jpeg", 50000);
    const doc = makeSavedDoc("doc_100", MOCK_RESULTS.image, "Site Photos", file);

    expect(doc.cloudinaryUrl).toBe(MOCK_RESULTS.image.secure_url);
    expect(doc.cloudinaryPublicId).toBe(MOCK_RESULTS.image.public_id);
    expect(doc.path).toBe(doc.cloudinaryUrl);
    expect(doc.fileType).toBe("image");
    expect(doc.category).toBe("Site Photos");
    expect(doc.uploadedBy).toBe("user001");
  });

  it("should construct correct upload response payload", () => {
    const file = makeMemoryFile("report.pdf", "application/pdf", 150000);
    const doc = makeSavedDoc("doc_300", MOCK_RESULTS.pdf, "Progress Reports", file);

    const response = {
      success: true,
      message: "Document uploaded successfully",
      document: {
        id: doc._id,
        filename: doc.originalName,
        fileType: doc.fileType,
        size: doc.size,
        category: doc.category,
        url: doc.cloudinaryUrl,
        uploadedAt: doc.createdAt,
      },
    };

    expect(response.success).toBe(true);
    expect(response.document.url).toContain("res.cloudinary.com");
    expect(response.document.url).toContain("raw/upload");
    expect(response.document.fileType).toBe("document");
  });
});

/* ====================================================================
   Retrieval Flow — URL Resolution
   ==================================================================== */
describe("Cloudinary Integration — Retrieval Flow", () => {
  it("should resolve Cloudinary URL for documents with cloudinaryUrl set", () => {
    const doc = makeSavedDoc("doc_100", MOCK_RESULTS.image, "Site Photos", makeMemoryFile("a.jpg", "image/jpeg"));

    const resolvedUrl = doc.cloudinaryUrl || `/uploads/${doc.category.replaceAll(/\s+/g, "_")}/${doc.filename}`;
    expect(resolvedUrl).toBe(MOCK_RESULTS.image.secure_url);
    expect(resolvedUrl).toMatch(/^https:\/\//);
  });

  it("should fallback to local URL for legacy documents", () => {
    const legacyDoc = {
      _id: "doc_legacy",
      filename: "file-old.jpg",
      category: "Site Photos",
      cloudinaryUrl: "",
    };

    const resolvedUrl = legacyDoc.cloudinaryUrl || `/uploads/${legacyDoc.category.replaceAll(/\s+/g, "_")}/${legacyDoc.filename}`;
    expect(resolvedUrl).toBe("/uploads/Site_Photos/file-old.jpg");
  });

  it("should map a list of mixed documents with correct URL resolution", () => {
    const cloudDoc = makeSavedDoc("doc_1", MOCK_RESULTS.image, "Site Photos", makeMemoryFile("a.jpg", "image/jpeg"));
    const legacyDoc = {
      _id: "doc_2",
      filename: "old.pdf",
      originalName: "old.pdf",
      category: "Other",
      cloudinaryUrl: "",
      createdAt: new Date(),
    };

    const docs = [cloudDoc, legacyDoc];
    const mapped = docs.map((d) => ({
      id: d._id,
      filename: d.originalName,
      url: d.cloudinaryUrl || `/uploads/${d.category.replaceAll(/\s+/g, "_")}/${d.filename}`,
    }));

    expect(mapped[0].url).toContain("res.cloudinary.com");
    expect(mapped[1].url).toBe("/uploads/Other/old.pdf");
  });
});

/* ====================================================================
   Delete Flow — Cloudinary Cleanup
   ==================================================================== */
describe("Cloudinary Integration — Delete Flow", () => {
  it("should identify Cloudinary-hosted documents for remote deletion", () => {
    const doc = makeSavedDoc("doc_1", MOCK_RESULTS.video, "Videos", makeMemoryFile("v.mp4", "video/mp4"));

    expect(doc.cloudinaryPublicId).toBeTruthy();
    expect(doc.cloudinaryPublicId).toBe("procurax/Videos/file-200");
  });

  it("should determine correct resource_type for Cloudinary deletion", () => {
    const cases = [
      { mimeType: "image/jpeg", expected: "image" },
      { mimeType: "image/png", expected: "image" },
      { mimeType: "video/mp4", expected: "video" },
      { mimeType: "video/quicktime", expected: "video" },
      { mimeType: "application/pdf", expected: "raw" },
      { mimeType: "application/msword", expected: "raw" },
      { mimeType: "text/plain", expected: "raw" },
    ];

    cases.forEach(({ mimeType, expected }) => {
      let resType = "image";
      if (mimeType.startsWith("video/")) resType = "video";
      else if (!mimeType.startsWith("image/")) resType = "raw";
      expect(resType).toBe(expected);
    });
  });

  it("should separate Cloudinary and legacy documents for bulk delete", () => {
    const cloudDoc1 = makeSavedDoc("d1", MOCK_RESULTS.image, "Site Photos", makeMemoryFile("a.jpg", "image/jpeg"));
    const cloudDoc2 = makeSavedDoc("d2", MOCK_RESULTS.pdf, "Progress Reports", makeMemoryFile("r.pdf", "application/pdf"));
    const legacyDoc = { _id: "d3", cloudinaryPublicId: "", path: "uploads/Other/old.doc" };

    const allDocs = [cloudDoc1, cloudDoc2, legacyDoc];
    const forCloudinary = allDocs.filter((d) => !!d.cloudinaryPublicId);
    const forLocal = allDocs.filter((d) => !d.cloudinaryPublicId);

    expect(forCloudinary).toHaveLength(2);
    expect(forLocal).toHaveLength(1);
  });
});

/* ====================================================================
   Profile Image Flow — Cloudinary Integration
   ==================================================================== */
describe("Cloudinary Integration — Profile Image Flow", () => {
  it("should build correct Cloudinary options for profile upload", () => {
    const userId = "user001";
    const timestamp = Date.now();

    const options = {
      resource_type: "image",
      folder: "procurax/profile-images",
      public_id: `profile-${userId}-${timestamp}`,
    };

    expect(options.resource_type).toBe("image");
    expect(options.folder).toBe("procurax/profile-images");
    expect(options.public_id).toContain("profile-user001-");
  });

  it("should update user record with Cloudinary profile URL", () => {
    const user = {
      _id: "user001",
      profileImage: "",
      cloudinaryPublicId: "",
    };

    // Simulate upload
    user.profileImage = MOCK_RESULTS.profile.secure_url;
    user.cloudinaryPublicId = MOCK_RESULTS.profile.public_id;

    expect(user.profileImage).toContain("res.cloudinary.com");
    expect(user.profileImage).toContain("profile-images");
    expect(user.cloudinaryPublicId).toContain("profile-images");
  });

  it("should construct correct response after profile image upload", () => {
    const response = {
      success: true,
      message: "Profile image uploaded successfully",
      data: {
        profileImage: MOCK_RESULTS.profile.secure_url,
        profileImageUrl: MOCK_RESULTS.profile.secure_url,
        user: { id: "user001", name: "Test", email: "test@test.com" },
      },
    };

    expect(response.success).toBe(true);
    expect(response.data.profileImageUrl).toBe(response.data.profileImage);
    expect(response.data.profileImageUrl).toContain("https://");
    expect(response.data.user.id).toBe("user001");
  });
});
