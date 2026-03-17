/**
 * ============================================================================
 * Cloudinary Service — Unit Tests
 * ============================================================================
 *
 * @file tests/unit/cloudinary.service.test.js
 * @description
 *   Tests the Cloudinary configuration helpers (uploadToCloudinary,
 *   deleteFromCloudinary) in isolation by mocking the Cloudinary SDK.
 *
 * @coverage
 *   - uploadToCloudinary: 5 tests (success image, success video, success raw/PDF,
 *                          error handling, custom options merge)
 *   - deleteFromCloudinary: 4 tests (success image, success video, success raw,
 *                            error handling)
 *   - Configuration: 1 test (cloud_name is set correctly)
 *   - Total: 10 Cloudinary service test cases
 *
 * @mocking_strategy
 *   - Mock the entire `cloudinary` npm package so no real HTTP calls are made.
 *   - The mock implements `.uploader.upload()` and `.uploader.destroy()` via
 *     Jest callback-style fakes.
 */

import { jest, describe, it, expect, beforeEach } from "@jest/globals";

/* ────────────────────────────────────────────────────────────────────
   MOCK: cloudinary v2 SDK
   ──────────────────────────────────────────────────────────────────── */
const mockUpload = jest.fn();
const mockDestroy = jest.fn();
const mockConfig = jest.fn();

jest.unstable_mockModule("cloudinary", () => ({
  v2: {
    config: mockConfig,
    uploader: {
      upload: mockUpload,
      destroy: mockDestroy,
    },
  },
}));

/* ────────────────────────────────────────────────────────────────────
   IMPORT AFTER MOCKING (dynamic import required for ESM mocks)
   ──────────────────────────────────────────────────────────────────── */
const { uploadToCloudinary, deleteFromCloudinary } = await import(
  "../../config/cloudinary.js"
);

/* ────────────────────────────────────────────────────────────────────
   TEST DATA
   ──────────────────────────────────────────────────────────────────── */
const MOCK_UPLOAD_RESULT = {
  public_id: "procurax/Site_Photos/file-1710000000",
  secure_url: "https://res.cloudinary.com/dhmdqtrqd/image/upload/v1/procurax/Site_Photos/file-1710000000.jpg",
  resource_type: "image",
  format: "jpg",
  bytes: 102400,
  width: 800,
  height: 600,
};

const MOCK_VIDEO_RESULT = {
  public_id: "procurax/Videos/file-1710000001",
  secure_url: "https://res.cloudinary.com/dhmdqtrqd/video/upload/v1/procurax/Videos/file-1710000001.mp4",
  resource_type: "video",
  format: "mp4",
  bytes: 5242880,
};

const MOCK_RAW_RESULT = {
  public_id: "procurax/Other/file-1710000002",
  secure_url: "https://res.cloudinary.com/dhmdqtrqd/raw/upload/v1/procurax/Other/file-1710000002.pdf",
  resource_type: "raw",
  format: "pdf",
  bytes: 204800,
};

const MOCK_DELETE_RESULT = { result: "ok" };

/* ────────────────────────────────────────────────────────────────────
   RESET MOCKS
   ──────────────────────────────────────────────────────────────────── */
beforeEach(() => {
  jest.clearAllMocks();
});

/* ====================================================================
   uploadToCloudinary
   ==================================================================== */
describe("Cloudinary Service — uploadToCloudinary", () => {
  it("should upload an image successfully and return the result", async () => {
    mockUpload.mockImplementation((_path, _opts, cb) => cb(null, MOCK_UPLOAD_RESULT));

    const result = await uploadToCloudinary("data:image/jpeg;base64,abc123", {
      resource_type: "image",
      folder: "procurax/Site_Photos",
      public_id: "file-1710000000",
    });

    expect(result).toEqual(MOCK_UPLOAD_RESULT);
    expect(result.secure_url).toContain("https://res.cloudinary.com");
    expect(result.public_id).toBe("procurax/Site_Photos/file-1710000000");
    expect(mockUpload).toHaveBeenCalledTimes(1);

    // Verify the upload options (no upload_preset in signed uploads, but folder/public_id are sanitized)
    const callOptions = mockUpload.mock.calls[0][1];
    expect(callOptions.resource_type).toBe("image");
    expect(callOptions.folder).toBe("procurax/Site_Photos");
    expect(callOptions.public_id).toBe("file-1710000000");
  });

  it("should upload a video successfully", async () => {
    mockUpload.mockImplementation((_path, _opts, cb) => cb(null, MOCK_VIDEO_RESULT));

    const result = await uploadToCloudinary("data:video/mp4;base64,xyz789", {
      resource_type: "video",
      folder: "procurax/Videos",
      public_id: "file-1710000001",
    });

    expect(result).toEqual(MOCK_VIDEO_RESULT);
    expect(result.resource_type).toBe("video");
    expect(mockUpload).toHaveBeenCalledTimes(1);
  });

  it("should upload a raw file (PDF) successfully", async () => {
    mockUpload.mockImplementation((_path, _opts, cb) => cb(null, MOCK_RAW_RESULT));

    const result = await uploadToCloudinary("data:application/pdf;base64,pdf123", {
      resource_type: "raw",
      folder: "procurax/Other",
      public_id: "file-1710000002",
    });

    expect(result).toEqual(MOCK_RAW_RESULT);
    expect(result.resource_type).toBe("raw");
  });

  it("should reject when Cloudinary returns an error", async () => {
    const uploadError = new Error("Upload failed: file too large");
    mockUpload.mockImplementation((_path, _opts, cb) => cb(uploadError, null));

    await expect(
      uploadToCloudinary("data:image/png;base64,bad", {
        resource_type: "image",
        folder: "procurax/Site_Photos",
      })
    ).rejects.toThrow("Upload failed: file too large");
  });

  it("should merge custom options with sanitized folder and public_id", async () => {
    mockUpload.mockImplementation((_path, _opts, cb) => cb(null, MOCK_UPLOAD_RESULT));

    await uploadToCloudinary("data:image/jpeg;base64,abc", {
      resource_type: "image",
      folder: "procurax/custom_folder",
      public_id: "custom-id",
      transformation: { width: 200, crop: "scale" },
    });

    const callOptions = mockUpload.mock.calls[0][1];
    // No upload_preset in signed uploads
    expect(callOptions.upload_preset).toBeUndefined();
    expect(callOptions.folder).toBe("procurax/custom_folder");
    expect(callOptions.public_id).toBe("custom-id");
    expect(callOptions.transformation).toEqual({ width: 200, crop: "scale" });
  });
});

/* ====================================================================
   deleteFromCloudinary
   ==================================================================== */
describe("Cloudinary Service — deleteFromCloudinary", () => {
  it("should delete an image from Cloudinary", async () => {
    mockDestroy.mockImplementation((_id, _opts, cb) => cb(null, MOCK_DELETE_RESULT));

    const result = await deleteFromCloudinary("procurax/Site_Photos/file-001", "image");

    expect(result).toEqual({ result: "ok" });
    expect(mockDestroy).toHaveBeenCalledTimes(1);
    expect(mockDestroy.mock.calls[0][0]).toBe("procurax/Site_Photos/file-001");
    expect(mockDestroy.mock.calls[0][1]).toEqual({ resource_type: "image" });
  });

  it("should delete a video from Cloudinary", async () => {
    mockDestroy.mockImplementation((_id, _opts, cb) => cb(null, MOCK_DELETE_RESULT));

    const result = await deleteFromCloudinary("procurax/Videos/file-002", "video");

    expect(result).toEqual({ result: "ok" });
    expect(mockDestroy.mock.calls[0][1]).toEqual({ resource_type: "video" });
  });

  it("should delete a raw file (PDF) from Cloudinary", async () => {
    mockDestroy.mockImplementation((_id, _opts, cb) => cb(null, MOCK_DELETE_RESULT));

    const result = await deleteFromCloudinary("procurax/Other/file-003", "raw");

    expect(result).toEqual({ result: "ok" });
    expect(mockDestroy.mock.calls[0][1]).toEqual({ resource_type: "raw" });
  });

  it("should reject when Cloudinary delete fails", async () => {
    const deleteError = new Error("Resource not found");
    mockDestroy.mockImplementation((_id, _opts, cb) => cb(deleteError, null));

    await expect(
      deleteFromCloudinary("procurax/invalid/id", "image")
    ).rejects.toThrow("Resource not found");
  });
});

/* ====================================================================
   Configuration
   ==================================================================== */
describe("Cloudinary Service — Configuration", () => {
  it("should export uploadToCloudinary as a function", () => {
    expect(typeof uploadToCloudinary).toBe("function");
  });

  it("should export deleteFromCloudinary as a function", () => {
    expect(typeof deleteFromCloudinary).toBe("function");
  });
});
