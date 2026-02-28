import Meeting from "../models/Meeting.js";

/*
  Find conflicting meetings for a specific user (owner).
  Optionally exclude a meeting ID (used during update/reschedule).
*/
export const findConflicts = async (startTime, endTime, excludeId = null, ownerId = null) => {
  const query = {
    done: false,
    startTime: { $lt: endTime },
    endTime: { $gt: startTime }
  };

  if (excludeId) {
    query._id = { $ne: excludeId };
  }

  // Only check conflicts for this user's meetings
  if (ownerId) {
    query.owner = ownerId;
  }

  return await Meeting.find(query);
};

/*
  Suggest the next available slot after conflicting meetings for the given user.
*/
export const suggestNextSlot = async (startTime, durationMinutes = 60, ownerId = null) => {
  const query = { done: false };
  if (ownerId) query.owner = ownerId;

  const meetings = await Meeting.find(query).sort({ startTime: 1 });

  let proposedStart = new Date(startTime);

  for (const meeting of meetings) {
    if (proposedStart < meeting.endTime) {
      proposedStart = meeting.endTime;
    }
  }

  return {
    suggestedStart: proposedStart,
    suggestedEnd: new Date(
      proposedStart.getTime() + durationMinutes * 60000
    )
  };
};
