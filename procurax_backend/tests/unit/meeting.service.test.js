/**
 * Meeting Service Unit Tests
 *
 * Tests the MeetingService business logic layer in isolation.
 * Covers CRUD operations, conflict detection, and slot suggestion.
 */

import { jest, describe, it, expect, beforeEach } from "@jest/globals";
import { AppError } from "../../core/errors/AppError.js";

/* ------------------------------------------------------------------ */
/*  Mock Mongoose model                                                */
/* ------------------------------------------------------------------ */
const mockSave = jest.fn();

const MockMeetingConstructor = jest.fn().mockImplementation(function (data) {
  Object.assign(this, data);
  this._id = { toString: () => "mtg_001" };
  this.createdAt = new Date("2024-06-01");
  this.updatedAt = new Date("2024-06-01");
  this.save = mockSave.mockResolvedValue(this);
});

const makeChainable = (resolvedValue) => ({
  sort: jest.fn().mockReturnThis(),
  skip: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  select: jest.fn().mockResolvedValue(resolvedValue),
});

MockMeetingConstructor.find = jest.fn();
MockMeetingConstructor.findOne = jest.fn();
MockMeetingConstructor.findOneAndUpdate = jest.fn();
MockMeetingConstructor.findOneAndDelete = jest.fn();
MockMeetingConstructor.countDocuments = jest.fn();

jest.unstable_mockModule("../../meetings/models/Meeting.js", () => ({
  default: MockMeetingConstructor,
}));

jest.unstable_mockModule("../../core/logging/logger.js", () => ({
  default: {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

const { default: MeetingService } = await import(
  "../../core/services/meeting.service.js"
);
const Meeting = MockMeetingConstructor;

/* ------------------------------------------------------------------ */
/*  Constants                                                          */
/* ------------------------------------------------------------------ */
const USER_ID = "507f1f77bcf86cd799439011";

const MOCK_MEETING = {
  _id: { toString: () => "mtg_001" },
  title: "Sprint Planning",
  description: "Plan sprint 12 tasks",
  location: "Conference Room A",
  startTime: new Date("2024-06-15T10:00:00Z"),
  endTime: new Date("2024-06-15T11:00:00Z"),
  priority: "high",
  done: false,
  owner: USER_ID,
  createdAt: new Date("2024-06-01"),
  updatedAt: new Date("2024-06-01"),
};

/* ------------------------------------------------------------------ */
/*  Test Suites                                                        */
/* ------------------------------------------------------------------ */
describe("MeetingService", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  /* -------------------- createMeeting -------------------- */
  describe("createMeeting", () => {
    it("should create a meeting when no conflicts exist", async () => {
      // findConflicts returns empty (no conflicts)
      const chain = makeChainable([]);
      Meeting.find.mockReturnValue(chain);
      mockSave.mockResolvedValueOnce(undefined);

      const result = await MeetingService.createMeeting(
        {
          title: "Sprint Planning",
          startTime: "2024-06-15T10:00:00Z",
          endTime: "2024-06-15T11:00:00Z",
        },
        USER_ID
      );

      expect(result).toHaveProperty("id", "mtg_001");
      expect(result).toHaveProperty("title", "Sprint Planning");
    });

    it("should throw conflict error when meetings overlap", async () => {
      const conflicting = [
        {
          _id: { toString: () => "mtg_existing" },
          title: "Existing Meeting",
          startTime: new Date("2024-06-15T10:30:00Z"),
          endTime: new Date("2024-06-15T11:30:00Z"),
        },
      ];

      // findConflicts returns conflicting meetings
      const conflictChain = makeChainable(conflicting);
      Meeting.find.mockReturnValueOnce(conflictChain);

      // suggestNextSlot needs its own chain
      const emptyChain = makeChainable([]);
      emptyChain.sort = jest.fn().mockResolvedValue([]);
      Meeting.find.mockReturnValueOnce(emptyChain);

      await expect(
        MeetingService.createMeeting(
          {
            title: "Overlapping",
            startTime: "2024-06-15T10:00:00Z",
            endTime: "2024-06-15T11:00:00Z",
          },
          USER_ID
        )
      ).rejects.toThrow("conflict");
    });
  });

  /* -------------------- getMeetings -------------------- */
  describe("getMeetings", () => {
    it("should return paginated meetings for a user", async () => {
      const chain = makeChainable(undefined);
      chain.limit = jest.fn().mockResolvedValue([MOCK_MEETING]);
      Meeting.find.mockReturnValue(chain);
      Meeting.countDocuments.mockResolvedValue(1);

      const result = await MeetingService.getMeetings(USER_ID);

      expect(result.meetings).toHaveLength(1);
      expect(result.meetings[0]).toHaveProperty("id", "mtg_001");
      expect(result.pagination).toHaveProperty("page", 1);
      expect(result.pagination.total).toBe(1);
    });

    it("should filter by done status", async () => {
      const chain = makeChainable(undefined);
      chain.limit = jest.fn().mockResolvedValue([]);
      Meeting.find.mockReturnValue(chain);
      Meeting.countDocuments.mockResolvedValue(0);

      await MeetingService.getMeetings(USER_ID, { done: true });

      expect(Meeting.find).toHaveBeenCalledWith(
        expect.objectContaining({ owner: USER_ID, done: true })
      );
    });

    it("should filter by date range", async () => {
      const chain = makeChainable(undefined);
      chain.limit = jest.fn().mockResolvedValue([]);
      Meeting.find.mockReturnValue(chain);
      Meeting.countDocuments.mockResolvedValue(0);

      await MeetingService.getMeetings(USER_ID, {
        startDate: "2024-06-01",
        endDate: "2024-06-30",
      });

      expect(Meeting.find).toHaveBeenCalledWith(
        expect.objectContaining({
          owner: USER_ID,
          startTime: expect.objectContaining({
            $gte: expect.any(Date),
            $lte: expect.any(Date),
          }),
        })
      );
    });
  });

  /* -------------------- getMeetingById -------------------- */
  describe("getMeetingById", () => {
    it("should return a meeting when found", async () => {
      Meeting.findOne.mockResolvedValue(MOCK_MEETING);

      const result = await MeetingService.getMeetingById("mtg_001", USER_ID);

      expect(result).toHaveProperty("id", "mtg_001");
      expect(result).toHaveProperty("title", "Sprint Planning");
    });

    it("should throw NotFound error when meeting doesn't exist", async () => {
      Meeting.findOne.mockResolvedValue(null);

      await expect(
        MeetingService.getMeetingById("nonexistent", USER_ID)
      ).rejects.toThrow("not found");
    });
  });

  /* -------------------- updateMeeting -------------------- */
  describe("updateMeeting", () => {
    it("should update meeting fields", async () => {
      const updated = { ...MOCK_MEETING, title: "Updated Title" };
      Meeting.findOneAndUpdate.mockResolvedValue(updated);

      const result = await MeetingService.updateMeeting("mtg_001", USER_ID, {
        title: "Updated Title",
      });

      expect(result).toHaveProperty("title", "Updated Title");
    });

    it("should check for conflicts when updating times", async () => {
      Meeting.findOne.mockResolvedValue(MOCK_MEETING);
      const chain = makeChainable([]);
      Meeting.find.mockReturnValue(chain);

      const updated = { ...MOCK_MEETING, startTime: new Date("2024-06-15T14:00:00Z") };
      Meeting.findOneAndUpdate.mockResolvedValue(updated);

      const result = await MeetingService.updateMeeting("mtg_001", USER_ID, {
        startTime: "2024-06-15T14:00:00Z",
      });

      expect(Meeting.findOne).toHaveBeenCalled();
      expect(result).toHaveProperty("id");
    });

    it("should throw NotFound error when meeting doesn't exist for update", async () => {
      Meeting.findOneAndUpdate.mockResolvedValue(null);

      await expect(
        MeetingService.updateMeeting("nonexistent", USER_ID, { title: "X" })
      ).rejects.toThrow("not found");
    });
  });

  /* -------------------- markMeetingDone -------------------- */
  describe("markMeetingDone", () => {
    it("should mark meeting as done", async () => {
      const done = { ...MOCK_MEETING, done: true };
      Meeting.findOneAndUpdate.mockResolvedValue(done);

      const result = await MeetingService.markMeetingDone("mtg_001", USER_ID);

      expect(result.done).toBe(true);
      expect(Meeting.findOneAndUpdate).toHaveBeenCalledWith(
        { _id: "mtg_001", owner: USER_ID },
        { $set: { done: true } },
        { new: true }
      );
    });

    it("should throw NotFound error when meeting doesn't exist", async () => {
      Meeting.findOneAndUpdate.mockResolvedValue(null);

      await expect(
        MeetingService.markMeetingDone("nonexistent", USER_ID)
      ).rejects.toThrow("not found");
    });
  });

  /* -------------------- deleteMeeting -------------------- */
  describe("deleteMeeting", () => {
    it("should delete a meeting and return success", async () => {
      Meeting.findOneAndDelete.mockResolvedValue(MOCK_MEETING);

      const result = await MeetingService.deleteMeeting("mtg_001", USER_ID);

      expect(result).toEqual({ success: true });
    });

    it("should throw NotFound error when meeting doesn't exist", async () => {
      Meeting.findOneAndDelete.mockResolvedValue(null);

      await expect(
        MeetingService.deleteMeeting("nonexistent", USER_ID)
      ).rejects.toThrow("not found");
    });
  });

  /* -------------------- normalizeMeeting -------------------- */
  describe("normalizeMeeting", () => {
    it("should return a plain object with id instead of _id", () => {
      const result = MeetingService.normalizeMeeting(MOCK_MEETING);

      expect(result.id).toBe("mtg_001");
      expect(result._id).toBeUndefined();
      expect(result).toHaveProperty("title");
      expect(result).toHaveProperty("startTime");
      expect(result).toHaveProperty("endTime");
      expect(result).toHaveProperty("priority");
      expect(result).toHaveProperty("done");
    });
  });

  /* -------------------- getUpcomingMeetings -------------------- */
  describe("getUpcomingMeetings", () => {
    it("should return upcoming meetings sorted by time", async () => {
      const chain = makeChainable(undefined);
      chain.limit = jest.fn().mockResolvedValue([MOCK_MEETING]);
      Meeting.find.mockReturnValue(chain);

      const result = await MeetingService.getUpcomingMeetings(USER_ID, 5);

      expect(result).toHaveLength(1);
      expect(Meeting.find).toHaveBeenCalledWith(
        expect.objectContaining({
          owner: USER_ID,
          done: false,
          startTime: expect.objectContaining({ $gte: expect.any(Date) }),
        })
      );
    });
  });
});
