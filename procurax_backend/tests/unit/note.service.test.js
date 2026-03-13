/**
 * Note Service Unit Tests
 *
 * Tests the NoteService business logic layer in isolation.
 */

import { jest, describe, it, expect, beforeEach } from "@jest/globals";
import { AppError } from "../../core/errors/AppError.js";

/* ------------------------------------------------------------------ */
/*  Mock Mongoose model                                                */
/* ------------------------------------------------------------------ */
const mockSave = jest.fn();

const MockNoteConstructor = jest.fn().mockImplementation(function (data) {
  Object.assign(this, data);
  this._id = { toString: () => "note_001" };
  this.createdAt = new Date("2024-01-15");
  this.lastEdited = new Date("2024-01-15");
  this.save = mockSave.mockResolvedValue(this);
});

MockNoteConstructor.find = jest.fn();
MockNoteConstructor.findOne = jest.fn();
MockNoteConstructor.findOneAndUpdate = jest.fn();
MockNoteConstructor.findOneAndDelete = jest.fn();
MockNoteConstructor.countDocuments = jest.fn();
MockNoteConstructor.distinct = jest.fn();

jest.unstable_mockModule("../../notes/notes.model.js", () => ({
  default: MockNoteConstructor,
}));

const { default: NoteService } = await import("../../core/services/note.service.js");
const Note = MockNoteConstructor;

/* ------------------------------------------------------------------ */
/*  Constants                                                          */
/* ------------------------------------------------------------------ */
const USER_ID = "507f1f77bcf86cd799439011";

const MOCK_NOTE = {
  _id: { toString: () => "note_001" },
  title: "Meeting Notes",
  content: "Discussed project milestones",
  tag: "meetings",
  createdAt: new Date("2024-01-15"),
  lastEdited: new Date("2024-01-15"),
  hasAttachment: false,
};

/* ------------------------------------------------------------------ */
/*  Test Suites                                                        */
/* ------------------------------------------------------------------ */
describe("NoteService", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  /* -------------------- createNote -------------------- */
  describe("createNote", () => {
    it("should create a note and return normalised output", async () => {
      mockSave.mockResolvedValueOnce(undefined);

      const result = await NoteService.createNote(
        { title: "Test Note", content: "Some content", tag: "general" },
        USER_ID
      );

      expect(result).toHaveProperty("id", "note_001");
      expect(result).toHaveProperty("title", "Test Note");
      expect(result).toHaveProperty("tag", "general");
    });

    it("should propagate database save errors", async () => {
      mockSave.mockRejectedValueOnce(new Error("DB error"));

      await expect(
        NoteService.createNote({ title: "Fail" }, USER_ID)
      ).rejects.toThrow("DB error");
    });
  });

  /* -------------------- getNotes -------------------- */
  describe("getNotes", () => {
    it("should return paginated notes for a user", async () => {
      const chainable = {
        sort: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue([MOCK_NOTE]),
      };
      Note.find.mockReturnValue(chainable);
      Note.countDocuments.mockResolvedValue(1);

      const result = await NoteService.getNotes(USER_ID);

      expect(Note.find).toHaveBeenCalledWith(
        expect.objectContaining({ owner: USER_ID })
      );
      expect(result.notes).toHaveLength(1);
      expect(result.pagination.total).toBe(1);
    });

    it("should filter by tag when provided", async () => {
      const chainable = {
        sort: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue([]),
      };
      Note.find.mockReturnValue(chainable);
      Note.countDocuments.mockResolvedValue(0);

      await NoteService.getNotes(USER_ID, { tag: "meetings" });

      expect(Note.find).toHaveBeenCalledWith(
        expect.objectContaining({ owner: USER_ID, tag: "meetings" })
      );
    });
  });

  /* -------------------- getNoteById -------------------- */
  describe("getNoteById", () => {
    it("should return a single note", async () => {
      Note.findOne.mockResolvedValue(MOCK_NOTE);

      const result = await NoteService.getNoteById("note_001", USER_ID);
      expect(result.id).toBe("note_001");
    });

    it("should throw NotFound when note missing", async () => {
      Note.findOne.mockResolvedValue(null);

      await expect(
        NoteService.getNoteById("bad_id", USER_ID)
      ).rejects.toThrow(AppError);
    });
  });

  /* -------------------- updateNote -------------------- */
  describe("updateNote", () => {
    it("should update and return the note", async () => {
      Note.findOneAndUpdate.mockResolvedValue({
        ...MOCK_NOTE,
        title: "Updated",
      });

      const result = await NoteService.updateNote("note_001", USER_ID, {
        title: "Updated",
      });

      expect(result.title).toBe("Updated");
    });

    it("should throw NotFound for non-existent note", async () => {
      Note.findOneAndUpdate.mockResolvedValue(null);

      await expect(
        NoteService.updateNote("bad", USER_ID, { title: "X" })
      ).rejects.toThrow(AppError);
    });
  });

  /* -------------------- deleteNote -------------------- */
  describe("deleteNote", () => {
    it("should delete and return success", async () => {
      Note.findOneAndDelete.mockResolvedValue(MOCK_NOTE);

      const result = await NoteService.deleteNote("note_001", USER_ID);
      expect(result).toEqual({ success: true });
    });

    it("should throw NotFound when note missing", async () => {
      Note.findOneAndDelete.mockResolvedValue(null);

      await expect(
        NoteService.deleteNote("bad", USER_ID)
      ).rejects.toThrow(AppError);
    });
  });

  /* -------------------- getUserTags -------------------- */
  describe("getUserTags", () => {
    it("should return distinct tags", async () => {
      Note.distinct.mockResolvedValue(["meetings", "personal", "work"]);

      const tags = await NoteService.getUserTags(USER_ID);

      expect(tags).toEqual(["meetings", "personal", "work"]);
      expect(Note.distinct).toHaveBeenCalledWith("tag", { owner: USER_ID });
    });
  });

  /* -------------------- normalizeNote -------------------- */
  describe("normalizeNote", () => {
    it("should return a plain object with id instead of _id", () => {
      const result = NoteService.normalizeNote(MOCK_NOTE);

      expect(result.id).toBe("note_001");
      expect(result._id).toBeUndefined();
      expect(result).toHaveProperty("title");
      expect(result).toHaveProperty("content");
      expect(result).toHaveProperty("tag");
      expect(result).toHaveProperty("lastEdited");
    });
  });
});
